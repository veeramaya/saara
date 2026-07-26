# Saara — Project Context

A single-file brief to seed another project with how Saara is built and why.
Saara is a **local-first, privacy-first personal integrity & productivity app**
by **Realmaya** (`com.realmaya.saara`). It helps a person keep their word:
tasks/events with honest scoring, on-device AI (bring-your-own-key), and
device-to-device sync that never routes personal data through a backend.

- **Repo (local):** `c:\dev\saara` · primary work branch `ledger-architecture`, base `main`
- **Current version:** `1.4.16+156` · **DB schema:** v14 · **tests:** ~191 green
- **No remote** configured yet (local Git only).

---

## 1. Tech stack

| Concern | Choice |
|---|---|
| UI / app | **Flutter / Dart** (Android, Windows desktop, iOS/macOS) |
| State | **Riverpod**, hand-written providers in `lib/providers.dart` (no heavy codegen for providers) |
| Local DB | **Drift** (SQLite) with **SQLCipher** encryption on every platform, incl. Windows |
| Secrets | `flutter_secure_storage` (Android Keystore / Windows DPAPI) — DB key & API keys live here, never in the DB |
| AI | **BYOK** (user's own provider key), device→provider directly. Deterministic core works with no AI |
| Google sync | `google_sign_in` (mobile) + a loopback+PKCE flow (desktop); **REST over http**, device→Google directly |
| Recurrence | `rrule` package |
| Crypto (sync file) | `encrypt` (AES-256-CBC) + `pointycastle` (PBKDF2) |

No backend server of our own. Nothing user-owned passes through Realmaya
infrastructure.

## 2. Architectural pillars

1. **Local-first & encrypted.** The SQLCipher DB is the source of truth. A random
   256-bit key is generated on first launch and kept only in the OS keystore.
   `lib/data/connection.dart` self-heals an orphaned DB (key lost) rather than
   bricking.
2. **Append-only ledger.** Scores/reports are a **fold over an append-only
   `TaskTransition` table**, never over mutable task state. Delete removes the
   future, not the past. See `docs/LEDGER_DESIGN.md`. This makes device merges
   conflict-free (union + dedupe by id).
3. **Two sync channels, kept distinct.**
   - **Google** (Tasks + Calendar) for interop with the outside world.
   - **Ledger file** (encrypted JSON bundle) for device↔device — carries what
     Google can't (area, publication state, history, provenance, participant
     phone numbers). **Never** goes through Google.
4. **BYOK AI, no proxy.** The AI agent can *act* (create/change with a confirm)
   and *find* (NLP search); it calls the user's provider directly.

## 3. Privacy / security constraints (hard rules)

These are non-negotiable and shaped many decisions:

- **BYOK AI only** — no proxy/backend that could see user data.
- **Never the Google Drive API.** Media archiving is plain filesystem only (an
  optional folder path — no OAuth scope, avoids CASA review).
- **OAuth scopes stay sensitive-only**: `tasks` + `calendar.events`. Adding any
  new scope (e.g. contacts) is avoided because it widens verification burden.
- API keys / DB key live **only** in Keystore/DPAPI, never in the DB.
- Event `reviewNotes` are **never synced**.
- Ledger sync is **device-to-device via file only**, never through Google.
- Health-sourced logs stay **device-local** (not in the ledger bundle).
- Contacts: names + an optional phone are stored locally; the number crosses
  **only** in the ledger between the user's own devices — never to Google.

## 4. Repository layout (`lib/`)

```
app.dart              Root shell: bottom nav (Today·Tasks·Areas·Progress·Saara), auto-sync
providers.dart        All Riverpod providers (DB, DAOs, services, derived state)
core/                 data dir, theme, time context, platform helpers
data/
  connection.dart     SQLCipher open + self-heal
  database.dart       Drift DB, schemaVersion, migrations, deviceId
  tables/             tasks, task_relations (TaskTransition ledger, participants), areas…
  daos/               task_dao, area_dao
domain/
  enums.dart          TaskStatus, TaskKind, PublicationState, LedgerEventKind, TaskSource…
  task_service.dart   THE creation funnel — every task is born here (writes the ledger)
  task_state_machine.dart   pure lifecycle transitions
  ledger_report.dart  the fold: scores derived from the ledger
  rrule_util.dart     bound a series (UNTIL)
  schedule_conflicts.dart   overlap detection (time-blocks only)
services/
  ledger_sync_service.dart  export/import encrypted bundle; unify by gcalEventId
  ledger_folder_sync.dart   watched-folder auto-sync
  app_settings.dart   key/value settings incl. device registry
  reset_service.dart  wipe local data (preserves DB key)
  contacts_service.dart     on-device contacts (names; number read on demand)
  google/             google_sync_service (REST), google_sync_orchestrator (reconcile)
features/             one folder per screen/feature (home, tasks/search, task_detail,
                      task_card, areas, agent (Saara), settings, google, contacts…)
```

## 5. Data & domain model highlights

- **Task**: title, kind (`task`|`event`), scheduledStart/dueDate, durationMin,
  `rrule`, areaId, `publicationState` (draft/released), `source`, Google link
  fields (`gcalEventId`, `gcalCalendarId`, `gcalEtag`, `lastSyncedAt`),
  `occurrenceSlot` (recurring identity), meeting/location, reminderOffsets.
- **TaskTransition** = the ledger. One row per event; `kind`
  (created/released/statusChange/deleted/corrected), `toStatus`, `at`, plus
  self-contained provenance: `areaId`, `titleSnapshot`, `deviceId`, `reason`.
  **Append-only** — never updated/deleted.
- **TaskParticipant**: contact ref (name + lookup key) + optional `phone`.
- **Area**: life area with base category, score derived from the ledger.
- **Time is absolute.** All timestamps are UTC-backed instants, displayed in the
  viewer's local zone. No floating/wall-clock concept (deliberate decision).

## 6. Sync model (the subtle part)

- **Google Tasks is date-only** — it cannot hold a time-of-day. A timed to-do
  pushed there flattens to midnight (shows e.g. 5:30 AM IST elsewhere). Fixes:
  (a) a task with a duration is routed to **Google Calendar** (which keeps the
  time); (b) a Google-Tasks sync **keeps the local time-of-day** and takes only
  Google's date; (c) recurring Calendar events must send an explicit
  `timeZone` (UTC) or Google rejects them.
- **Unify by `gcalEventId`.** The same external item imported on two devices
  mints different local ids; on ledger import we fold them into one and remap
  the history. The **ledger is authoritative** for Saara-owned fields (area,
  disposition, real clock time); **Google is authoritative only for event-facts
  of external invites** you don't own.
- **Any device can edit/delete safely** — no "source device" lock; the merge
  reconciles. Provenance ("Added on Desktop · synced 3h ago") is *shown*, not
  enforced, via a device registry that rides the bundle.

## 7. Notable patterns / conventions

- **Single creation funnel**: everything goes through `TaskService.create`, so no
  task exists without a `created` ledger entry and correct publication state.
- **Corrections, not edits**, for area re-filing (an adjusting entry; reporting
  follows the correction, the original posting stands).
- **Deterministic first, AI optional**: parser/overlap/recurrence are pure and
  testable; AI is an enhancement, never required.
- **Errors are surfaced, not swallowed** (e.g. a Calendar sync failure is shown
  in the sync screen, not hidden).
- **Provider invalidation discipline**: a mutation invalidates every list/detail
  provider that shows it (a recurring source of "stale view" bugs when missed).
- **Tests are regression-first**: a `FakeGoogle` seam, in-memory Drift DBs for
  two-device merge tests, migration backfill tests.

## 8. Build & release

- **Desktop (Windows):** `powershell -ExecutionPolicy Bypass -File tool\deploy_desktop.ps1`
  — builds `flutter build windows --release`, copies out of `build\` to a stable
  folder (default `D:\Saara`), bundles the MSVC runtime DLLs. Needs OpenSSL for
  SQLCipher's CMake. Opens **maximized**.
- **Android (Play):** `flutter build appbundle --release` → AAB. Play internal
  testing first; version code must be unique and monotonically increasing.
- **Google Cloud setup** (for a dev): OAuth **Desktop** + **Android** clients,
  People/Tasks/Calendar APIs enabled, consent screen in **Testing** with the
  tester added as a **Test user** (sensitive scopes only allow listed testers
  until verified/published). See `docs/GOOGLE_SYNC_SETUP.md`.

## 9. Related docs in this repo

- `docs/LEDGER_DESIGN.md` — the ledger's design decisions.
- `saara-prd.md` — product requirements (§ references throughout the code).
- `docs/PLAY_DATA_SAFETY.md`, `docs/privacy.html`, `PLAY_GO_LIVE.md`,
  `PLAY_STORE.md` — store submission material.
- `DESKTOP_BUILD.md`, `GOOGLE_SYNC_SETUP.md`, `PHASE3.md`.

---

### If you're starting a related project, the transferable ideas

1. **Append-only ledger + fold** for anything that needs honest history and
   conflict-free multi-device merge.
2. **Two-channel sync**: a lossy interop channel (a third-party API) + a
   lossless owner-only channel (an encrypted file) that carries what the first
   can't — with a clear authority split per field.
3. **Local-first + BYOK + no backend** as a privacy posture, and keeping OAuth
   scopes minimal to stay clear of platform security reviews.
4. **Absolute-time storage**, deterministic core with optional AI, and a single
   creation funnel that guarantees invariants.
