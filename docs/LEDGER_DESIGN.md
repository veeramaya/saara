# Saara — ledger architecture

Status: **design, not yet built**
Branch: `ledger-architecture` · rollback point: `git checkout v1.0.124-pre-ledger`

---

## 1. Why

### 1.1 The integrity hole (single device — this is the main reason)

Scores are computed from **current task state**, not from history:

```dart
// providers.dart — areaScoresProvider
final tasks = await taskDao.tasksForArea(a.id);   // WHERE deleted_at IS NULL
final done  = tasks.where((t) => disposed.contains(t.status));
score = completed / done.length;
```

So **deleting a missed task raises your score** — the evidence leaves the
denominator. Reopening and re-completing rewrites the past the same way.

For an app whose premise is honest self-measurement, the number can't be
editable by tidying up. This is true on one device, with no sync involved.

### 1.2 The cross-device split

Transitions, areas, and a task's area assignment never leave the device. Google
Tasks/Calendar have no field for them, and there is no Realmaya server. So a
second device shows tasks with **no area at all**, and still renders a score it
cannot justify. Two devices, two different numbers, one of them meaningless.

### 1.3 The class of bug it removes

Every sync bug this project has hit came from **mutating shared state** —
last-writer-wins picking wrong, per-date copies multiplying, deletes not lining
up. Append-only logs merge by union-and-dedupe. There is no conflict to resolve
because nothing is ever updated.

---

## 2. The model

Borrowed from double-entry accounting, as proposed:

| Accounting | Saara |
|---|---|
| Transactions (immutable postings) | **Ledger events** — append-only, never edited |
| Chart of accounts | **Reference data** — areas, result definitions |
| Reports (derived) | Scores, reliability, integrity wheel — a *fold* over events |

Three consequences:

1. **Reporting = a fold.** Two devices holding the same events compute the same
   score, deterministically. "As of last sync" becomes precise, not a fudge.
2. **Merge is conflict-free.** Union events, dedupe by id.
3. **Export/import falls out.** An export *is* a ledger segment; import appends
   what you haven't seen. Idempotent — importing twice changes nothing.

### 2.1 Two channels, different jobs

- **Google** — interop with the outside world (calendar, Meet, other apps).
- **Ledger file** — Saara's own record, device to device.

Both stay. Google was never the right carrier for the ledger; it was just the
only pipe that existed. **The ledger must never be smuggled through Google** —
that is precisely what produced 208 duplicate tasks.

---

## 3. What is and isn't a ledger event

### 3.1 Events (append-only, merged)

| Event | Source today | Notes |
|---|---|---|
| Task transition | `TaskTransitions` | Already append-only — verified, no UPDATE or DELETE anywhere |
| Manual measurable log | `MeasurableLogs` | User-entered values only — see below |

### 3.2 NOT events

**Health-sourced measurable logs.** `deleteLogsForResultInRange()` deletes and
re-inserts a day's values on every Health Connect refresh. That is a
*projection* of Health Connect, not a fact Saara witnessed — and merging it
would be actively wrong (device A replaces a value, device B still holds the old
row, merge resurrects it).

→ Health logs stay **device-local and unmerged**. Health Connect is already
per-device, so nothing is lost. This requires a `source` column on
`MeasurableLogs` to tell manual from health-derived; today there is none.

**Reference data** — areas, measurable-result definitions, and a task's current
title/schedule. These are state, not history. Merged separately (§5.2).

### 3.3 Entries must be self-contained

A ledger entry carries the facts needed to interpret it, at the time it
happened — exactly as an accounting posting records the account code rather than
a pointer that can be re-classified later.

So a transition gains:

| Field | Why |
|---|---|
| `areaId` | The area **at the time**. Re-assigning a task later must not rewrite past scores. |
| `titleSnapshot` | So another device can report on it without holding the task row. |
| `deviceId` | Provenance. Which device witnessed this. |

Without these, interpreting another device's ledger requires its `Tasks` table
too — which defeats the point.

---

## 4. Reporting

Scores derive from events, not from current rows.

- Never join to `tasks` and filter `deleted_at` — that is the hole in §1.1.
- A disposition that happened, happened. Deleting the task afterwards removes it
  from your lists, **not from your record**.
- Trash/restore, edits and re-assignment change the future, never the past.

### 4.1 Governing principle

> **Saara measures the integrity of the records. Integrity itself belongs to the
> user.** The app cannot manufacture it — only reflect faithfully what was
> recorded. Its job is to be an honest recorder, not a policeman.

Everything below follows from that. Saara does not obstruct, nag, or moralise;
it declines to *forget on demand*, which is a different and smaller claim.

### 4.2 Deletion policy

The distinction is **whether anything actually happened**, not whether the row
is convenient to remove:

| What is deleted | Behaviour | Why |
|---|---|---|
| An **open** task — created, never started or disposed | Removed. No ledger events exist beyond its creation, so nothing is lost. **No score effect.** | Changing your mind about a plan you never acted on is ordinary housekeeping, not a broken commitment. |
| A task **with history** — started, completed, missed, rejected | Soft-deleted and gone from your lists. Its events stand, and the deletion is itself recorded. **Score unaffected by the deletion.** | You did the thing, or you didn't. Removing the row afterwards doesn't unmake it. |

This answers the obvious objection — *"I deleted it, why is it still counting
against me?"* — cleanly: **it can only count against you if you actually missed
it.** Delete a plan you never started and nothing happens at all.

### 4.3 Creation events and abandoned plans

Creation *is* recorded (§9.1), so a created-then-deleted open task leaves both a
`created` and a `deleted` event. That is deliberate: the facts are preserved, but
**reporting excludes a task deleted while still open** from "commitments made".

Facts kept; interpretation fair. The record stays complete for anyone who later
wants to look, without penalising legitimate planning changes.

---

## 5. Merge rules

### 5.1 Events

```
for each incoming event:
    if id already present -> skip
    else insert
never update, never delete
```

Ids are UUIDs, so collision-free. The operation is **commutative and
idempotent**: order doesn't matter, repeats are harmless, partial syncs are
safe.

### 5.2 Reference data (areas, result definitions)

Last-writer-wins per row on `updatedAt`. Small, slow-changing surface. A losing
edit is a lost rename, not lost history.

### 5.3 Deletion

Deleting a task soft-deletes the row and leaves its events untouched. There is
no operation that removes a ledger entry — including "Reset local data", which
wipes the whole device and is documented as unrecoverable.

---

## 6. Transport — file, not cloud

### 6.1 Shape

Each device **writes only its own file**, so two devices can never write the
same file and there is no write conflict:

```
<folder>/saara-ledger-<deviceId>.saara
```

Contents: device id, schema version, its events, its reference snapshot.
Encrypted with a user passphrase — these files often land in cloud folders.

### 6.2 The folder is the user's choice

Saara does **filesystem I/O only** and talks to no cloud API. If the user points
the folder at OneDrive, Dropbox, a NAS, or a synced SSD, propagation is
automatic — and that is *their* decision, not an integration. Same pattern
already chosen for media archiving.

### 6.3 Size

A transition is ~100 bytes. 20 tasks/day × 3 transitions ≈ 6 KB/day ≈ **2 MB a
year**. Full re-import each time is cheap, so no watermark is needed at first —
idempotency makes it safe.

---

## 7. Migration

Existing rows are backfillable **because no cross-device merge has ever run** —
every entry in a device's ledger was necessarily recorded by that device.

| Field | Backfill |
|---|---|
| `deviceId` | This device's id |
| `areaId` | The task's current area (approximation — documented) |
| `titleSnapshot` | The task's current title |

The approximation is honest and one-time. It must happen **before the first
merge**, after which unattributed entries become genuinely ambiguous.

---

## 8. Phases

**Phase 1 — reporting derives from the ledger.**
Enrich transitions (areaId, title, deviceId) + backfill; rewrite
`areaScoresProvider` and reliability as a fold. Fixes §1.1 with no sync
involved. Largest and most delicate — the score *is* the app.

**Phase 2 — export/import.**
Bundle format, encryption, idempotent merge, import UI. Manual file move.

**Phase 3 — watched folder.**
Pick a folder; write on change, read peers on open. Convenience only.

**Phase 4 — launch.**

Phase 1 stands alone and ships value even if 2–4 never happen.

---

## 9. Decisions (settled)

1. **Creation is an event.** Enables "commitments made vs kept", which is close
   to Saara's purpose. Abandoned open plans are excluded at the *reporting*
   layer, not by discarding the fact (§4.3).
2. **Captures do not travel in ledger files.** Media stays on the device that
   captured it. It can be carried manually in a full Export, so it is
   *portable by effort, not by default*.
   → Accepted trade-off: making media portable by default would mean central
   storage, which contradicts "Realmaya holds nothing". Local media is the price
   of that guarantee, and it is the right price.
3. **One passphrase for ledger files**, set once. Lose it and the files are
   unreadable — stated with the same bluntness as Reset local data.
4. **Both devices are full equals.** With merge working there is no master and
   no satellite; each holds the complete record as of its last sync.

---

## 10. Still open

- **Device id generation** — random UUID on first run, stored in `Settings`, with
  a user-visible friendly name ("Veera's desktop") so provenance is legible.
- **Does the `deleted` event carry a reason?** Optional free text, or nothing.
  Leaning nothing: prompting for a reason edges toward moralising, which §4.1
  rules out.
