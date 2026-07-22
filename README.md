# Saara

A local-first personal integrity & productivity agent (Realmaya). Flutter,
single codebase, Android-first. See `saara-prd.md` for the full build spec.

> **Non-negotiables (§1):** local-first, zero data capture; deterministic Tier‑0
> core that works with **no AI configured**; all outbound sharing via the user's
> own apps/accounts; encrypted on-device SQLite.

---

## Phase 1 scope (§17)

This scaffold covers the Phase 1 (MVP) surface:

DB + state machine · deterministic parser · task card · home timeline ·
morning/evening flows · local notifications · recurring engine · task migration
(offline Excel/CSV import) · settings · feedback mailto.

> Two PRD Phase-1 items are temporarily removed to unblock the Android build —
> **Todoist import** (replaced by Excel/CSV) and **text share-target** (its
> plugin requires an unpublishable `compileSdk 37`). Both are tracked in the
> deferred table below.

> **Migration note:** the PRD's Todoist import (§12) is deferred. Phase 1 ships a
> simpler, fully-offline **file import** (Excel `.xlsx` or `.csv`) instead
> (`services/import/`, `features/import/`) — no API token, no network. Both
> formats feed one shared grid parser; recognized headers: Title (required),
> Due, Notes, Area, Priority, Repeat.

Phases 2–4 (Calendar sync, captures, health, listeners, on-device AI, iOS,
BYOK) are stubbed as clearly-labelled placeholders where they touch Phase 1.

---

## First-time setup

The project uses **code generation** (Drift + companions). Two commands must run
before the app or tests will compile — until then your IDE will show
"undefined class `Task`/`AppDatabase`/`…Companion`" and "URI hasn't been
generated: `*.g.dart`". **Those errors are expected and clear after step 2.**

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Then:

```bash
flutter run              # hot-reload on a connected device
flutter test             # unit tests
flutter analyze
```

> Notifications behave realistically only in **release/profile** builds — test
> the 07:00 / 21:00 cycle over real days, with battery optimization ON, and add
> the manufacturer autostart exemption prompt on Xiaomi/Oppo/Vivo (§18.2).

---

## Running on desktop (dev convenience)

Desktop builds are for **fast UI iteration only** — the PRD ships Android/iOS.
Two platform shims make it run:

- **DB:** **macOS** works with full SQLCipher encryption (linked via the pod).
  Windows/Linux have neither SQLCipher nor a bundled plain-sqlite lib (the app
  ships `sqlcipher_flutter_libs`, not `sqlite3_flutter_libs`), so the DB won't
  open there without a system sqlite3 — a non-goal while Windows desktop is
  blocked on the C++ toolchain anyway. Treat macOS as the only real desktop target.
- **Notifications:** `flutter_local_notifications` has no Windows/Linux impl, so
  `NotificationService` no-ops on those (macOS is supported).

Everything else in Phase 1 (parser, task CRUD, state machine, morning/evening
flows, Excel/CSV import, feedback mailto, seeded Areas) works on desktop.

```bash
# Windows — needs Visual Studio 2022 with "Desktop development with C++"
flutter config --enable-windows-desktop   # usually already on
flutter run -d windows

# macOS — needs Xcode
flutter run -d macos
```

> `workmanager` and `receive_sharing_intent` are mobile-only but aren't wired
> into desktop startup, so they don't break the build.

---

## Architecture

```
lib/
├─ main.dart                     # bootstrap: notifications init → ProviderScope
├─ app.dart                      # M3 shell: NavigationBar (Today·Areas·Captures·Saara·Settings)
├─ core/
│  └─ theme.dart                 # §20 Material 3, deep-teal brand seed, light/dark
├─ data/                         # §3 persistence (Drift + SQLCipher)
│  ├─ connection.dart            # encrypted connection; key in Keystore/Keychain
│  ├─ database.dart              # @DriftDatabase (all §3 tables) + DAOs   ⟵ generates database.g.dart
│  ├─ converters.dart            # JSON list TypeConverters
│  ├─ tables/                    # one file per §3 table group
│  └─ daos/                      # task_dao (ledger writes), area_dao       ⟵ generate *.g.dart
├─ domain/                       # deterministic core (Tier 0 — no AI)
│  ├─ enums.dart                 # §3/§4 enums (persisted by name — do not reorder)
│  ├─ task_state_machine.dart    # §4 — pure; computes transition outcomes + ledger rows
│  ├─ task_service.dart          # applies outcomes atomically via TaskDao
│  └─ parser/                    # §5 pipeline: links, date/duration/RRULE grammar, area guess
├─ services/
│  ├─ notification_service.dart  # §8 local morning/evening agent
│  ├─ recurring_engine.dart      # §4/§8 RRULE → idempotent task instances
│  ├─ feedback_service.dart      # §14 mailto veera@realmaya.com (nothing auto-sent)
│  └─ import/                    # offline Excel/CSV migration: parse → dry-run → commit
├─ features/                     # §7 screens: home, task_card, morning, evening,
│  │                             #             areas, settings, todoist, placeholder
└─ providers.dart               # Riverpod wiring (manual providers — no extra codegen)
```

### The integrity ledger (§3.3, §4) — read this before touching tasks

`TaskTransition` rows are the source of truth. **Every status change goes
through `TaskStateMachine` → `TaskService` → `TaskDao.applyTransition`**, which
writes the new task state and its transition row in one transaction. Reports are
computed from the ledger, never from mutable `Task.status` alone.

Rules the machine enforces:
- `missed` is only reachable with `finalizedInReview: true` — i.e. presented in
  the evening review / morning brief. **No silent auto-missing.**
- `rescheduled` closes the current instance and spawns a new one, linked through
  the transition note.
- terminal states (`completed`/`missed`/`rejected`/`rescheduled`) have no
  forward transitions; past edits go through a separate "amend log" flow (§4,
  not yet built).

---

## Security & privacy posture

- **DB encryption:** SQLCipher via `sqlcipher_flutter_libs`; a random 256-bit
  passphrase is generated on first launch and stored only in
  Keystore/Keychain (`data/connection.dart`). `connection.dart` asserts
  `PRAGMA cipher_version` is non-empty so a mis-link to plain SQLite fails loud.
- **No raw API keys in the DB** — `ApiCredential` holds only a Keystore alias
  (§3.6). Todoist token lives in secure storage for the import session (§12).
- **No telemetry.** Feedback is a user-initiated `mailto:` only (§14).
- **Network:** the only outbound traffic in Phase 1 is user-initiated Todoist
  import. Verify airplane-mode operation of all other flows (§18.5).

---

## What's intentionally deferred (with pointers)

| Area | Status in this scaffold | Phase |
|---|---|---|
| Google Calendar sync | `Task` has `gcal_*` columns; no sync engine | 2 (§9) |
| Contacts / participants | parser flags tokens; no on-device match | 2 (§5.3, §11) |
| Captures (text/audio/video) | `Capture` table only; UI placeholder | 2 (§16) |
| Measurable results scoring | tables + area cards; ring is a stub | 2/3 (§10) |
| Listeners + Gmail send / Drive | tables only | 3 (§13, §16) |
| On-device AI (Tier 1) | Settings shows "Not supported"; parser has hook | 3 (§6) |
| Voice (§19) | mic affordances only | 2/3 |
| Share-target text intake (§11) | removed for now — plugin needs unpublishable compileSdk 37 | 2 (with image/OCR) |
| WorkManager nightly rollover | removed for now — 0.5.x won't compile on current Kotlin/AGP | 2 (§8) |
| Todoist import (§12) | replaced by offline Excel import for now | later, if wanted |
| Onboarding (§20.3) | 6 starter Areas seeded on first launch; no name/rename flow yet | Phase 1 follow-up |

---

## Testing

`test/` covers the deterministic pieces that need no codegen:
`date_grammar`, `link_detector`, `recurrence_phrase_mapper`, and the
`task_state_machine` transition matrix. A full state-machine outcome test
against an in-memory Drift DB should be added once `build_runner` has run.
