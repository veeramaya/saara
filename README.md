# Saara

A **local-first, privacy-first** personal integrity & productivity app by
**Realmaya** (`com.realmaya.saara`). Flutter, single codebase — Android + Windows
desktop (iOS/macOS supported). It helps you keep your word: honest,
ledger-derived scoring, on-device **bring-your-own-key** AI, and device-to-device
sync that never routes personal data through a backend.

> **📄 Start here for architecture:** [`docs/PROJECT_CONTEXT.md`](docs/PROJECT_CONTEXT.md)
> — a one-file brief of the stack, pillars, decisions, and layout.
> Deep-dive on the core model: [`docs/LEDGER_DESIGN.md`](docs/LEDGER_DESIGN.md).
> Full product spec: [`saara-prd.md`](saara-prd.md).

**Status:** `1.4.16+156` · DB schema **v14** · ~191 tests green · primary branch
`ledger-architecture`.

> **Non-negotiables:** local-first, zero data capture; a deterministic core that
> works with **no AI configured**; BYOK AI (no proxy/backend sees your data); all
> outbound sharing via the user's own apps/accounts; encrypted on-device SQLite;
> OAuth scopes kept sensitive-only (`tasks`, `calendar.events`).

---

## What's built

Ledger architecture (append-only, honest scoring) · Google **Tasks + Calendar**
two-way sync (device→Google directly) · **device-to-device sync** via an
encrypted ledger file (never through Google) · **BYOK AI agent** that can *act*
(create/change with a confirm) and *find* (NLP search) · recurring tasks with an
end date · captures (text/audio/video/image) · on-device contacts with
**Call / WhatsApp** from a task · morning/evening flows · local notifications ·
offline Excel/CSV import · provenance + last-sync display.

---

## First-time setup

The project uses **code generation** (Drift). Run these before the app or tests
compile — until then the IDE shows "undefined class `Task`/`AppDatabase`" and
"URI hasn't been generated: `*.g.dart`", which clear after step 2:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Then:

```bash
flutter run              # hot-reload on a connected device
flutter test             # unit tests (~191)
flutter analyze
```

## Build & release

```bash
# Android app bundle for Play (internal testing first; version code must be unique + increasing)
flutter build appbundle --release        # → build/app/outputs/bundle/release/app-release.aab

# Windows desktop — SQLCipher-encrypted like mobile. Needs OpenSSL for SQLCipher's CMake
# (see DESKTOP_BUILD.md). Builds, copies out of build\ to a stable folder, opens maximized.
powershell -ExecutionPolicy Bypass -File tool\deploy_desktop.ps1
```

Google setup for a dev (OAuth Desktop + Android clients, APIs enabled, test
users): [`GOOGLE_SYNC_SETUP.md`](GOOGLE_SYNC_SETUP.md).

---

## Architecture (short version — full detail in `docs/PROJECT_CONTEXT.md`)

```
lib/
├─ main.dart            bootstrap → ProviderScope
├─ app.dart            root shell: Today · Tasks · Areas · Progress · Saara; auto-sync
├─ providers.dart      all Riverpod providers (manual — no provider codegen)
├─ core/               data dir, theme, time context, platform helpers
├─ data/               Drift + SQLCipher: connection (self-heal), database (schema/migrations),
│                      tables/ (tasks, TaskTransition ledger, participants, areas), daos/
├─ domain/             deterministic core: task_service (creation funnel), task_state_machine,
│                      ledger_report (the fold), rrule_util, schedule_conflicts, enums
├─ services/           ledger_sync (encrypted bundle), google/ (sync + reconcile),
│                      contacts, app_settings, reset, recurring_engine
└─ features/           one folder per screen (home, search/tasks, task_detail, task_card,
                       areas, agent (Saara), settings, google, contacts …)
```

### The integrity ledger — read before touching tasks

`TaskTransition` rows are the source of truth. **Every task is born through
`TaskService.create`, and every status change goes through
`TaskStateMachine → TaskService → TaskDao`**, writing task state and the ledger
row in one transaction. Scores/reports are a **fold over the ledger**, never over
mutable `Task.status`. Delete removes the future, not the past. This is what makes
two-device merges conflict-free (union + dedupe by id).

---

## Security & privacy posture

- **DB encryption** on every platform (SQLCipher). A random 256-bit key is
  generated on first launch and kept only in Keystore/DPAPI — never in the DB.
  `connection.dart` fails loud if plain SQLite is linked, and self-heals an
  orphaned DB rather than bricking.
- **BYOK AI, no proxy** — the agent calls the user's provider directly.
- **Two sync channels**: Google (interop) and an **encrypted ledger file**
  (device↔device only, never through Google) that carries what Google can't
  (area, history, provenance, participant phone numbers).
- **Never the Google Drive API**; media archiving is plain filesystem only.
- **No telemetry.** Feedback is a user-initiated `mailto:` only.

---

## Docs

| File | What |
|---|---|
| [`docs/PROJECT_CONTEXT.md`](docs/PROJECT_CONTEXT.md) | one-file architecture brief (start here) |
| [`docs/LEDGER_DESIGN.md`](docs/LEDGER_DESIGN.md) | the ledger's design decisions |
| [`saara-prd.md`](saara-prd.md) | product requirements (§ references throughout the code) |
| [`DESKTOP_BUILD.md`](DESKTOP_BUILD.md) · [`GOOGLE_SYNC_SETUP.md`](GOOGLE_SYNC_SETUP.md) | dev setup |
| [`PLAY_GO_LIVE.md`](PLAY_GO_LIVE.md) · [`PLAY_STORE.md`](PLAY_STORE.md) · [`docs/PLAY_DATA_SAFETY.md`](docs/PLAY_DATA_SAFETY.md) | store submission |
