# Saara Sync — the CRDT / G-Set model

*A plain-language record of how Saara's serverless, ledger-based sync works and why
it can't conflict. Written to catch up on later. Grounded in
[`lib/services/ledger_sync_service.dart`](../lib/services/ledger_sync_service.dart)
(`importBundle`).*

---

## The one-line idea

> The ledger is a **bag of unique facts that only ever grows**. Syncing is pouring
> two bags together and keeping one of each. Pour in any order, as many times as
> you like — you always end up with the same bag.

No server decides who wins. Convergence is **math**, not coordination.

---

## What a CRDT is

**CRDT = Conflict-free Replicated Data Type** — a data structure deliberately
built so independent copies on different devices can be edited offline and then
**merged automatically, with no coordinator, always landing on the same result.**
No locks, no central authority picking a winner, no manual "merge conflict".

## The simplest CRDT: a grow-only set (G-Set)

A set you can only **add** to, never remove. Merging two replicas = **set union**
(all elements either side has seen). Union works flawlessly because it has three
algebraic properties:

| Property | Meaning | Why it matters |
|---|---|---|
| **Commutative** | A ∪ B = B ∪ A | Sync order doesn't matter |
| **Associative** | (A∪B)∪C = A∪(B∪C) | Any grouping of syncs is fine |
| **Idempotent** | A ∪ A = A | Re-syncing changes nothing |

Any set of devices, merging in any order, any number of times → **the same final
set.** That is the whole reason no server is needed.

---

## Saara is *two CRDTs stacked*

### 1. The ledger → a G-Set (preserves everything)

Each `TaskTransition` has a unique `id`. Merge = *"insert the entries whose id I
don't already hold"*:

```dart
// ledger, append-only — the whole reason merging can't conflict
if (!await _exists(db.taskTransitions, e.id)) {
  await db.into(db.taskTransitions).insert(e);
}
```

That is set-union keyed by id; skipping duplicates is the idempotence. The ledger
**can never conflict and never loses an event.** Scores/reliability are a **fold
over this ledger**, so every device that has merged the same events computes the
*same* numbers.

### 2. The row state → an LWW-Register (resolves, occasionally drops)

The **materialized rows** (task title, area, due date; also areas & results) use
**last-writer-wins by `updatedAt`** — via `_isNewer(...)`. This is *also* a CRDT
(an **LWW-Register** / LWW-Map). It still always converges (newest timestamp
wins, deterministically), so it's conflict-*free* — but unlike the G-Set it's
**lossy**: two devices editing the *same field* concurrently keep only the newer
edit; the older one is discarded.

**Net effect:**
- History + reliability score → **never lost** (G-Set).
- Current field values → **always agree**, but a simultaneous edit to the same
  field between syncs can drop the loser (LWW).

This is not a bug — it's the two CRDT semantics doing their different jobs.

---

## Why it works across N devices (not just 2)

Because union is commutative + associative + idempotent, **any number** of devices
converge — 2 laptops + 2 phones, or more.

- The **transport** (Wi-Fi QR sync) is pairwise: two devices at a time.
- But each device exports the **entire ledger it holds** (including events it
  learned from others), so events **gossip transitively**:

```
Laptop1 ↔ Mobile1     Mobile1 now holds Laptop1's events
Mobile1 ↔ Laptop2     Laptop2 gets Laptop1's events too, via Mobile1
Laptop2 ↔ Mobile2     Mobile2 now holds everything
```

You don't need to pair every device with every other — just enough sync paths
that events can reach everyone.

---

## Portability & backup (the honest edge)

- Switching devices isn't a "restore" — a new device just **merges the ledger**
  and folds the same history into the same state. The ledger *is* the backup.
- Because there's **no server**, the safety net is **only as fresh as your last
  sync or export.** A device lost/wiped before syncing its newest events has no
  cloud copy to fall back on.
- Escape hatch already built: the **encrypted export file** is a full ledger
  snapshot — drop one into a folder / share it to yourself for a portable,
  restore-anywhere backstop without reintroducing a server.

---

## Future direction: serverless invites (blockchain's good half, not the chain)

Sharing an invite is just emitting a signed ledger event and getting it into
another user's ledger. "Blockchain" bundles three things; Saara wants only two:

1. **Signed, append-only, tamper-evident events** ✅ want
2. **Cryptographic identity without accounts** (per-user keypair) ✅ want
3. **Global consensus / ordering / anti-double-spend** ❌ don't need

(3) exists to stop double-spending a scarce token. A commitment isn't scarce and
needs no global order — so the right model is a **web of trust** (signed events +
existing CRDT union), *not* a chain. That's lighter and more private than a
blockchain.

**Transport is the real constraint, not trust:**
- *Invite-as-signed-blob over any channel* (WhatsApp/Signal/email) → **truly
  serverless**, and basically already designed.
- *Live device-to-device over the internet* → hits NAT/firewalls; realistically
  needs a **minimal, blind rendezvous** (sees only ciphertext) or a DHT bootstrap.
  "Zero server" and "live internet P2P" are in tension.

**The special part:** signed events let a person carry a **portable, verifiable
reliability record** ("proof I kept 92% of my commitments") that no server owns
and no one can forge — self-sovereign reputation, the teeth behind P-Integrity's
"others own the mirror" (see [`INTEGRITY_FRAMEWORK.md`](INTEGRITY_FRAMEWORK.md)).
If ever built, the order is: **keypair identity → signed events → invite-as-blob
over any channel** first; a blind rendezvous only if live P2P is wanted. The chain
never enters the picture.

---

## TL;DR

- **CRDT** = merge without coordination, always converges.
- **G-Set** = add-only set, merge = union (commutative, associative, idempotent).
- Saara's **ledger is a G-Set** → never conflicts, never loses history/scores.
- Saara's **row state is an LWW-Register** → always agrees, may drop a concurrent
  field edit.
- N devices converge; events gossip transitively over pairwise syncs.
- Backup = "as good as your last sync/export"; the ledger is its own backup.
