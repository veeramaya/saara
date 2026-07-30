# The Integrity Framework

*The canonical statement of how Saara turns commitments into a measure of
integrity — and, more importantly, into a way of **growing** it. Every scoring
and status decision should trace back to this document.*

---

## The governing principle

> **The system owns facts. The user owns judgment. Others own the mirror.**

A single number is **not** an accurate representation of a person's integrity.
So Saara never pretends it is. It keeps a **factual, indisputable score** as a
spine, and surrounds it with **insights** — timeliness, self-assessed quality,
and the gap between what you say and what the people you gave your word to
actually experienced. The score tells you *whether* you kept your word; the
insights are where a person actually develops.

---

## Layer 1 — The Timeline (fact, system-owned, indisputable)

Every transition — created, released, started, completed, missed, cancelled,
rescheduled — is timestamped in the append-only ledger. It is never edited and
never disputed. From it, one fact is derived that matters everywhere:

- **On-time vs late** is measured against the **end / due time** (for a task
  with only an end date and no start, the end time is the sole reference).

Timeline facts (a delay, an early close) are **not shown as "status"** — they
are computed and surfaced as *insight* (Layer 3). The status stays clean; the
timeline stays pure.

---

## Layer 2 — The Score (binary, factual)

For each commitment **you own**, one factual question: *did the word happen?*

| Outcome | Meaning | Effect |
|---|---|---|
| **Kept** | You did it | **+1**, in the numerator and denominator |
| **Broken** | You gave your word and didn't keep it — a miss, a no-show, or backing out of your own commitment | counts **against** you (denominator only) |
| **Not counted** | The commitment dissolved without breaking your word — you rescheduled (re-committed), or an external event was cancelled/rescheduled by its source | **excluded** from the score entirely |

`reliability = kept ÷ (kept + broken)`. "Not counted" never moves the number.

**A late completion is still Kept (+1).** You did it — that's factual and
indisputable. "Delayed ≠ full integrity" is expressed by the **timeliness**
metric in Layer 3, *not* by fuzzing the score. Blending lateness into the score
would make it arguable ("how late is late?"), which would violate Layer 1's own
"no dispute."

### The commitment gate: draft → released

- A **draft** is not yet a commitment. It shows, but it does **not count** — you
  are still deciding. Dropping a draft is free.
- **Releasing it (saving it, not as a draft) is the act of honouring it.** From
  that moment you own it, and it is scored as honoured or not honoured.
- You **cannot self-exempt** a released commitment by rejecting it. The only
  neutral exits after release are **reschedule** (you re-commit to a new time)
  or an **external cancellation** (see Events).

---

## Dispositions → scoring

The choice the user makes maps to the score like this. The disposition menu
should make these distinct rather than collapsing them into one ambiguous
"reject":

| Disposition | Score |
|---|---|
| **Completed** (on-time or early) | **Kept** |
| **Completed late** | **Kept** — and counts against the *timeliness* insight |
| **Rescheduled** (you move it and re-commit) | **Not counted now**; the new occurrence is scored when it arrives — it doesn't fall on the original timeline |
| **Cancelled my own commitment** / **missed** / **no-show** | **Broken** |
| **External event cancelled or rescheduled by its source** | **Not counted** → insight only |

The critical clarification: **backing out of your own word is Broken, not
free.** Only re-commitment (reschedule) and things outside your control
(external changes) are neutral.

---

## Events: internal vs external

An **event** is a released, time-blocked commitment. There are two origins, and
both, once **released (non-draft)**, are **owned** by you:

1. **Created** — you author it.
2. **Received** — you copy an invitation, or it arrives via sync. *(Let the user
   mark this provenance as "invitation received," not "created" — see
   Provenance.)*

Once released, the rule is identical regardless of origin:

- **Honoured** → Kept · **Not honoured** (it stood and you didn't) → Broken.
- **The one neutral exit is the event itself going away** — cancelled or
  rescheduled by its source. That dissolves the commitment through no fault of
  yours → **Not counted**, surfaced as insight.
- Your **own** reschedule of an event you created → **Not counted now**; the new
  occurrence is scored later. Your **own** cancellation of an event you created →
  **Broken**.

---

## Provenance: created vs received

Saara records where a commitment came from (authored, conversation, share
target, calendar sync). This is elevated to a user-facing distinction:

- **Created** — you initiated the word.
- **Invitation received** — it was handed to you, and by releasing it you chose
  to honour it.

Provenance never changes *whether* an owned commitment is scored — a released
invitation is as binding as one you created. It changes the **context** the
insights speak in ("you honour what you *create* 95% of the time, but what you
*accept* only 70%").

---

## Layer 3 — The Insights (developmental; user + listeners)

This is where integrity is actually grown, because it holds what a number
cannot:

- **Timeliness.** On-time rate and delay patterns, from Layer 1. A person who
  keeps every word but a third of them late learns something the raw score
  hides.
- **Quantity / quality — the user's judgment.** The system cannot measure *how
  well* something was done, so it never tries. Completion is **1** regardless.
  The user may record "100%" or "partial" as a **self-assessment** — kept out of
  the score, kept for reflection.
- **Self vs listener — the mirror.** A promise isn't fully kept until it lands
  with the person you gave it to. Saara correlates your self-assessment with the
  listener's experience and reports the **gap**:
  - You say *partial*, the listener says *it met expectation* → you undersell
    your reliability.
  - You say *100%*, the listener says *it didn't land* → the word technically
    happened, but the relationship it was for didn't feel it.

  Saara does not adjudicate who is right. It shows the correlation and leaves the
  judgment to you. That gap, seen honestly over time, is the work.

  **Delivered as an AI-enhanced insight** (your own key, §6) — not a fixed
  formula. The self-assessment and the listener's feedback are read *in context*
  by the model, so the reflection is nuanced ("you consistently undersell the
  ones that involve other people") rather than a rigid correlation coefficient.

---

## Bottom line

The **score is the trustworthy skeleton**; the **insights are the muscle**.
Saara measures what it can know for certain (did the word happen, and when) and
is deliberately **humble about what it cannot** (how well, and how it landed) —
handing those back to the person and the people around them. Read together, the
score and its insights are a **holistic way of developing a person's
integrity** — not a scoreboard that mistakes a number for the truth.

---

## Implementation status

- ✅ **Self-cancellation is a broken word.** `TaskStatus.cancelled` scores as
  **broken**; `rejected` stays **declined / excluded**. The disposition menu
  splits into Start · Complete · **Reschedule** (re-commit, not counted) ·
  **Cancel — I'm not doing it** (broken) · **No longer happening** (external, not
  counted, shown only for events / received items). Pre-release drop is free (a
  draft never counts).
- ✅ **Score realigned.** `committed = completed + missed + cancelled`; declined
  is excluded — in both the ledger score and the header/report summary, which
  previously disagreed.
- ✅ **External vs internal cancellation separated** via the two disposition
  choices above.
- ✅ **Timeliness** is a parallel metric (on-time rate), never blended into the
  score — a late completion is still Kept.
- ✅ **P-Integrity** named and put **upfront** (first coach card).
- ⏳ **Self-vs-listener gap → AI-enhanced insight** (fast-follow, §6).
- ⏳ **"Invitation received" provenance:** the `source` value and the external
  handling are in; the create-time *toggle* to set it is a small fast-follow.
