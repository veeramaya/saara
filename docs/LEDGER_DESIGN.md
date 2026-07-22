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

### 4.1a Draft and Released

A task or event has a **publication state**, orthogonal to its lifecycle status:

| State | Your own devices | Google (interop) | Counted in reporting | Deletable |
|---|---|---|---|---|
| **Draft** | **Syncs** | No | **No** | Freely |
| **Released** | Syncs | Syncs | Yes | Future only (§4.2) |

**A draft is in the ledger and travels with it** — sketch a week on the desktop
and it is on your phone. It simply does not move the books. This is exactly the
accounting distinction between an **unposted** entry and a **posted** one:
present, visible, carried along, but not counted until posted.

Drafts stay out of **Google**, though. Google is where the outside world sees
your calendar; putting half-formed thinking there makes it public before you
meant it to be, and clutters a calendar other people may share.

> Releasing is **giving your word**. Before that it is thinking out loud, and
> thinking out loud should cost nothing — sketch a week, change your mind, throw
> it away, and none of it touches your record.

### 4.1b The moment of commitment is itself a fact

`released` is a ledger event with a timestamp, not a flag that quietly flips.

That means the record can answer *when you gave your word*, and the gap between
committing and acting becomes visible — how far ahead you commit, whether things
sit in draft for weeks, whether you release and then immediately miss. For an
app about integrity, the moment of commitment is at least as interesting as the
moment of completion.

It also settles the deletion tension with no special-casing: you may delete
freely right up to the moment you commit, and after that §4.2 applies.

### 4.2 Deletion policy

> **Delete removes the future, never the past.**
> *"I cannot undo or edit my past. The past is past — there is nothing you can
> do. What you can alter is the current and the future you are living into."*

Once a task or event has moved out of `created` into any other state, it
happened — it existed in your plan or your execution — and the record of that
stands. Deleting it stops it going forward; it does not reach backwards.

| What | Behaviour |
|---|---|
| **Draft**, any state | Deleted outright. Nothing was committed, nothing was reported. |
| **Released**, still `created` — never acted on | Removed going forward. No transitions exist, so nothing leaves the record. |
| **Released**, has transitioned | **The past stands.** For a repeating task, delete ends future occurrences and keeps the ones that already happened. For a single one, there is no future to remove — the record simply remains. |

The recurring case is where this rule earns its keep: deleting a daily habit
stops tomorrow's occurrence and leaves last week's completions and misses
exactly as they were. That is the behaviour §4.2 always implied and now states
directly.

> Whole-device **Reset local data** is the one exception, and a deliberate one:
> an explicit, confirmed, documented-as-unrecoverable wipe of everything. That
> is a different act from quietly removing one inconvenient row.

It also answers the obvious objection — *"I deleted it, why is it still counting
against me?"* — cleanly: **it can only count against you if you actually did or
missed it.** Delete a draft, or a plan you never started, and nothing happens.

### 4.3 Corrections, not erasures

If the past cannot be deleted, genuine mistakes need a path. Miscategorisation
is the common case: *a "watch a video" task filed under Health when it belonged
in Entertainment.*

The instinct is to delete it. The right answer is to **correct** it — and to
record that a correction happened:

- Re-categorising a disposed task posts a **correction event**
  (`Health → Entertainment`, at time T, with an optional reason).
- Nothing is erased. The original posting and the correction both stand.
- This is the accounting parallel exactly: you never rub out an entry, you post
  an adjusting one.

**Reporting uses the corrected category.** The user is fixing a data-entry error,
not revising the past to flatter themselves — and because the correction is
recorded and visible, the honesty is preserved without the score being stuck
with a typo.

### 4.4 Reasons are for the user, not for the app

A deletion or correction may carry a short **reason**, because *the pattern is
worth learning from*: "I keep filing entertainment under health" is a useful
thing to notice about yourself.

Rules that keep this from becoming policing (§4.1):

- **Always optional.** Never a blocking prompt, never a required field.
- **Surfaced back to the user only** — in their own review, as "what you changed
  and why". It is never scored, never penalised, never shown to anyone else.
- The app does not ask "why?" in a tone that implies you owe it an answer.

### 4.5 Creation events and abandoned plans

Creation *is* recorded (§9.1), so a created-then-deleted open task leaves both a
`created` and a `deleted` event. Deliberate: the facts are preserved, but
**reporting excludes a task deleted while still open** from "commitments made".

Facts kept; interpretation fair.

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
- **Does a new task start as Draft or Released?** (§4.1a) The single biggest UX
  call in this design.
  - *Released by default* — quick-add stays one step; "Save as draft" is opt-in
    for planning. Keeps the app fast; risks people committing without meaning to.
  - *Draft by default* — committing becomes a deliberate act, which matches
    "releasing is giving your word". But it puts a second step in front of every
    task, and an app that is slow to capture doesn't get used.

  Leaning: **Released by default for quick capture, Draft for anything created in
  a planning context** (bulk import, sketching a week ahead, AI-extracted items
  awaiting review — which is already a review queue today). Needs a call before
  Phase 1a, since it changes the schema.
- **What replaces Delete on a Released task with history?** The action can't just
  vanish, or the UI looks broken. Leaning *"Hide from lists"* — the row leaves
  your views, the record stands. "Not a policeman" (§4.1) argues for letting
  people tidy their screen; the guarantee is about the **record**, not about
  forcing someone to keep looking at a task.
- **Does a correction move past-period scores?** §4.3 says yes (it fixes a
  data-entry error). The stricter accounting reading would post the adjustment
  to the current period and leave prior periods as-reported. Revisit if Saara
  ever issues fixed period statements; rolling scores make the simple answer
  right for now.
