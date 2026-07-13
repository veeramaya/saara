# SAARA — Product Requirements Document (Build Spec)

**Product:** Saara ("whole and complete") — a local-first personal integrity & productivity agent
**Company:** Realmaya Private Limited · realmaya.com
**Platforms:** Android (primary/first), iOS
**Version:** PRD v1.4 — July 2026 (free app + feedback channel; §19 Voice; §20 UI & avatar; area display names)
**Intended reader:** Claude Code / developer building the app in VS Code

---

## 1. Product vision & principles

Saara is a personal agent that helps a user give their word (tasks, commitments, measurable results across life Areas), keep it, and be witnessed keeping it by people they choose (committed listeners). Inspired by integrity-as-workability distinctions: every commitment gets a conscious disposition — done, missed, rescheduled, or rejected — never silent decay.

**Non-negotiable architecture principles:**

1. **Local-first, zero data capture.** All user data lives on-device in encrypted SQLite. Realmaya operates NO backend that stores user data. The only permissible server-side component is an optional anonymous FCM topic for announcements (no user identifiers stored).
2. **Deterministic core.** All parsing, monitoring, scoring, streaks, and reports work with rules/SQL — no AI required. The app is fully functional with zero AI configured.
3. **On-device AI when available.** Gemini Nano (Android AICore/ML Kit GenAI) and Apple Foundation Models (iOS 18+, iPhone 15 Pro+) enhance NLP. Graceful fallback on unsupported devices is a first-class path, not an edge case.
4. **User-owned channels.** All outbound sharing (listener reports, captures, exports) goes through the user's own apps/accounts (share sheet, user's Gmail token, user's Drive). Saara never sends anything from its own infrastructure.
5. **Calm agent rhythm.** Saara speaks twice a day (morning brief, evening review). Per-task reminders are a separate opt-in layer.

## 2. Tech stack

- **Framework:** Flutter (stable channel), single codebase.
- **Local DB:** Drift (SQLite) with SQLCipher encryption. DB key stored in Android Keystore / iOS Keychain.
- **State management:** Riverpod.
- **Background work:** WorkManager (Android), BGTaskScheduler (iOS) via workmanager plugin.
- **Notifications:** flutter_local_notifications (all reminders local; no push required for core function).
- **Date NLP:** any_date / chrono-style parsing extended with custom grammar (Section 6).
- **On-device AI:** Platform channels → ML Kit GenAI APIs (Android) / Foundation Models framework (iOS).
- **Auth to Google:** google_sign_in + PKCE OAuth. Scopes: `calendar` (read/write), `gmail.send` (listener reports, opt-in), `drive.file` (capture archive, opt-in). Request scopes incrementally, only when the feature is first used.
- **Media:** camera / record plugins; video H.265 720p default (1080p toggle), hard cap 3:00; audio AAC, cap 10:00.
- **IAP:** none — the app is free (see §14). No billing SDKs included.
- **Maps/navigation:** deep links (`google.navigation:` on Android, Maps URL scheme on iOS). Geofencing via platform geofence APIs (foreground-registered).
- **Health:** health plugin → Health Connect (Android) / HealthKit (iOS).
- **Contacts:** flutter_contacts, on-device matching only; contacts are never uploaded anywhere.

## 3. Data model (Drift/SQLite schemas)

All tables include `id` (uuid), `created_at`, `updated_at`. Soft-delete via `deleted_at` where noted.

### 3.1 Area
```
Area {
  id,
  base_category ENUM(health, family, finance, work, relationships, custom),
       -- drives parser keywords, health verification mapping, report grouping
  display_name TEXT,             -- user's quirky name, e.g. "Diehard", "Oneness–Sweetmango";
                                 -- defaults to base category name; editable anytime; shown/spoken everywhere
  icon, color,
  purpose_statement TEXT,        -- user's declared intent for this area
  sort_order INT, archived BOOL
}
-- UI rule: display_name is used in all screens, notifications, voice output (§19.3) and
-- listener reports; base_category appears only as a small subtitle chip on the area page.
-- Voice intents (§19.2 area_status) match against BOTH display_name and base_category.
```

### 3.2 MeasurableResult
```
MeasurableResult {
  id, area_id FK,
  title,                         -- "Walk 8,000 steps"
  metric_type ENUM(count, duration_min, boolean, numeric, health_steps,
                   health_active_min, health_sleep_hr, health_weight, task_completion_pct),
  target_value REAL, comparator ENUM(gte, lte, eq),
  cadence ENUM(daily, weekly, monthly), days_per_cadence INT NULL,  -- "5 days a week"
  verification ENUM(health_source, task_logs, manual_log),
  start_date, end_date NULL, active BOOL
}
```

### 3.3 Task
```
Task {
  id, title, notes TEXT,
  area_id FK NULL,
  status ENUM(created, started, in_progress, completed, missed, rejected, rescheduled),
  scheduled_start DATETIME NULL, duration_min INT NULL,
  due_date DATETIME NULL,
  completed_at DATETIME NULL, time_to_complete_min INT NULL,  -- actual, from started→completed
  rrule TEXT NULL,               -- iCalendar RRULE for repetition
  parent_recurring_id FK NULL,   -- instance → template link
  meeting_link TEXT NULL, meeting_provider ENUM(zoom, teams, meet, webex, other) NULL,
  location_name TEXT NULL, lat REAL NULL, lng REAL NULL, geofence_enabled BOOL,
  reminder_offsets TEXT NULL,    -- JSON [-15,-60] minutes; NULL = no per-task reminder (default)
  gcal_event_id TEXT NULL, gcal_calendar_id TEXT NULL, gcal_etag TEXT NULL,
  source ENUM(manual, conversation, share_target, gcal_sync, todoist_import),
  priority INT DEFAULT 0, deleted_at
}
TaskParticipant { task_id FK, contact_lookup_key TEXT, display_name }  -- on-device contact refs only
TaskTransition { id, task_id FK, from_status, to_status, at DATETIME, note TEXT NULL }
```
Every status change writes a TaskTransition row. **This log is the integrity ledger** — reports are computed from it, never from mutable state alone.

### 3.4 Capture (unified system)
```
Capture {
  id, type ENUM(text, audio, video),
  media_path TEXT NULL,          -- local encrypted storage path
  text_content TEXT NULL, caption TEXT NULL,
  duration_sec INT NULL,         -- enforce: video ≤ 180, audio ≤ 600
  size_bytes INT,
  attached_type ENUM(task, day, week, area), attached_id TEXT,  -- day: 'YYYY-MM-DD', week: 'YYYY-Www'
  archived BOOL DEFAULT false, archive_uri TEXT NULL,  -- user's Drive/iCloud file ref
  thumbnail_path TEXT NULL       -- kept locally even when archived
}
```

### 3.5 CommittedListener
```
CommittedListener {
  id, contact_lookup_key, display_name, channel ENUM(email, whatsapp_share, sms_share),
  email TEXT NULL,
  scope ENUM(all, area, task), scope_id TEXT NULL,
  frequency ENUM(weekly, daily, on_miss_escalation),
  include_captures BOOL DEFAULT false,
  consent_confirmed_at DATETIME   -- user confirmed the person agreed to receive reports
}
```

### 3.6 Supporting tables
```
SaaraGroup { id, name, member_lookup_keys JSON }           -- in-app groups (NOT WhatsApp scraping)
DayLog { date PK, opened_at NULL, committed_at NULL, closed_at NULL, reflection_capture_id NULL }
HealthSnapshot { date, metric, value }                     -- cached daily pulls
Settings { key PK, value }                                 -- includes ai_tier, notif times, storage cap, quality
ApiCredential { provider PK, key_alias }                   -- alias into Keystore/Keychain; raw keys NEVER in DB
```

---

## 4. Task state machine

```
created ──start──▶ started ──▶ in_progress ──▶ completed (sets completed_at, time_to_complete)
   │                  │              │
   │                  └──────┬───────┘
   ├── due passes, no action ─▶ missed        (set by evening review / day rollover, never silently)
   ├── user declines ─────────▶ rejected      (requires optional one-line reason)
   └── user moves ────────────▶ rescheduled   (creates new task instance linked via TaskTransition note)
```

Rules:
- `missed` is only finalized at the **evening review or next morning brief** — the user must see it. No background auto-missing without presentation.
- Recurring templates never change status; each generated instance does.
- `rescheduled` closes the current instance and spawns a new one (new scheduled_start); the chain is traceable through transitions.
- Editing a completed/missed task in the past requires an explicit "amend log" confirmation (integrity ledger discipline).

## 5. Deterministic parser (Tier 0 NLP)

Pipeline over raw input (typed text or share-target extraction):

1. **Link detection** — regex for zoom.us, teams.microsoft.com, meet.google.com, webex.com → meeting_link + provider.
2. **Date/time/duration** — chrono-style parser + custom grammar:
   - recurrence keywords: `every|daily|weekdays|weekends|every other|1st|2nd <weekday> of month` → RRULE
   - duration: `for 45 min|45m|1.5 hr|half an hour` → duration_min
   - relative: `tomorrow|next tue|in 3 days|tonight` (tonight = 20:00 default)
3. **Participants** — token match against on-device contacts (display name, nickname); ≥1 match → TaskParticipant; ambiguous → chip picker.
4. **Location** — match against saved places + "at <capitalized phrase>" heuristic → offer place confirmation.
5. **Area guess** — keyword dictionary per area (user-extendable), e.g. gym/walk/doctor → Health. Low confidence → leave unassigned, ask in card.
6. **Title** — input minus consumed tokens, cleaned.

**Confidence scoring:** each extractor returns 0–1. If composite < 0.6, show the pre-filled task card with uncertain fields highlighted; offer "Ask Saara" (Tier 1 on-device model) if available, else quick-fill chips. Never create a task silently from low-confidence parse.

## 6. AI tiers

- **Tier 0 (always):** parser above + all monitoring/reports via SQL. App is complete here.
- **Tier 1 (on-device model, auto-enabled when hardware supports):** Gemini Nano / Apple Foundation Models. Uses: (a) messy conversational task entry → structured JSON (use iOS guided generation / constrained decoding where available); (b) multi-task brain-dump splitting; (c) friendlier phrasing of daily brief lines. Detect availability at startup; expose status in Settings ("Saara's on-device intelligence: Active / Not supported on this device").
- **Tier 2 (export — "Ask your AI"):** app composes a structured package (relevant logs + engineered prompt, instructing JSON reply for imports) → share sheet → user's own ChatGPT/Gemini/etc. Import-back parser accepts pasted JSON. **Redaction toggle** replaces contact names/locations with placeholders. One-line disclosure: "You're sharing personal logs with a third-party AI — review their data settings."
- **Tier 3 (BYO API key, off by default):** provider picker (Anthropic/OpenAI/Gemini/custom OpenAI-compatible endpoint incl. Ollama). Key stored in Keystore/Keychain only. Used for in-app conversational entry + coaching dialogue + narrative weekly insight. All calls device→provider direct.

## 7. Screens & UX flows (simplicity target: WhatsApp-grade)

1. **Home:** Today timeline (tasks merged with Google Calendar events, duration blocks), area rings (progress vs measurable results), FAB with three actions: type/talk a task, capture, quick-add. Home header rotates integrity/completion quotes (public-domain/attributed only — see 15).
2. **Task card (create/confirm):** single card, pre-filled by parser; fields: title, date/time, duration, repeat, area, participants (contact chips), location, meeting link, reminder toggle, notes. One primary button: Save.
3. **Morning brief — "Open your day"** (local notification, default 07:00, adjustable): Android notification body carries precomputed summary line via WorkManager; iOS uses warm generic line, content built on tap. Screen: today's plan in timeline, conflicts flagged, travel-time warnings for located tasks, **yesterday's open items demanding disposition** (reschedule/reject/missed — no silent carryover), today's area targets. CTA: "Commit to today" → DayLog.committed_at.
4. **Evening review — "Complete your day"** (default 21:00): one-tap disposition per remaining task, health metrics pulled & scored vs targets, streaks updated, optional reflection capture (text/audio/video), tomorrow preview. Sunday: extends into weekly report with "Ask your AI" and "Send to committed listeners" actions.
5. **Areas:** list → area page: purpose statement, measurable results with verification status (✓ from health/logs), task list, **capture timeline (progress strip)** with side-by-side/sequential **compare view** (pick any two captures).
6. **Captures:** journal timeline across all entities; filters by area/type/date. Recorder UIs mimic WhatsApp (hold-to-record audio; video with 3:00 countdown ring, auto-stop).
7. **Listeners:** add from contacts, choose scope (all/area/task), frequency, include-captures toggle, consent confirmation step. Report preview before every send; send via user's Gmail (if scope granted) or share sheet.
8. **Settings:** notification times, per-task reminder defaults, AI tier controls + key entry + on-device status, storage meter (per-area) + cap + archive settings, send feedback (mailto veera@realmaya.com), import (Todoist), Google account & scopes, export-all (JSON+media zip to user's chosen location).

## 8. Notification engine

- Two daily agent notifications (morning/evening) — local, scheduled ahead; if user opens app within ±45 min window, present the review flow in-app and cancel the notification (no double-prompt).
- Per-task reminders: **opt-in per task**; defaults suggested for tasks with meeting links (-15 min) and located tasks (travel-time based: distance via last known location → "leave by" alert; foreground location + geofence only, NO background location tracking in v1).
- Escalation rules (deterministic): configurable, e.g. "3rd miss in a week for area X → flag in evening review → offer to include in listener report."
- WorkManager jobs: nightly rollover (generate recurring instances, finalize dispositions shown), pre-brief summary computation, health snapshot pull, gcal delta sync.

## 9. Google Calendar sync

- OAuth PKCE from device; CalendarList → user picks calendars to merge (includes other accounts' calendars added in their Google Calendar).
- Two-way: Saara tasks with scheduled_start+duration → events (extended property `saara_task_id`); external events display in timeline (read-only unless user converts to task). Incremental sync tokens; conflict rule: last-writer-wins with etag check, surface conflicts in evening review.
- Store compliance: sensitive-scope verification required — privacy policy on realmaya.com/saara stating on-device-only processing, demo video. Add own Google account as test user during development.

## 10. Health integration

Health Connect (Android) / HealthKit (iOS): steps, active minutes, sleep, weight (extensible). Daily snapshot cached to HealthSnapshot; measurable results with `verification=health_source` auto-score. Read-only scopes, requested only when a health-verified result is first created.

## 11. Share-target task creation (WhatsApp/Gmail/anywhere)

- Android: `ACTION_SEND` intent filters (text/*, image/*); iOS: Share Extension.
- Text → parser pipeline → pre-filled task card (2 taps to save).
- Image (screenshot/photo of an invitation) → on-device OCR (ML Kit Text Recognition / Apple Vision) → same pipeline.
- WhatsApp group invite links shared in → stored as named SaaraGroup reference for outbound sharing. **Explicitly out of scope: reading WhatsApp group membership/messages programmatically** (no public API; policy-violating workarounds prohibited).

## 12. Todoist import (Phase 1 feature)

- **Path A (primary): Todoist REST API v2 with user's personal token** (Settings → Integrations → Developer in Todoist). Fetch projects, sections, tasks (content, description, due incl. recurring string, priority, labels), completed history where accessible. Device→Todoist direct; token held in Keystore only for the import session unless user opts to keep for re-sync.
- Mapping wizard: projects → Areas (user confirms/merges), labels → area keywords or notes, priority 1–4 → priority, due.is_recurring strings → RRULE via mapping table (`every day`→FREQ=DAILY; `every mon, wed`→FREQ=WEEKLY;BYDAY=MO,WE; `every 2 weeks`→INTERVAL=2; unmappable → import as non-recurring + flag list shown post-import).
- **Path B: CSV import** via file picker (Todoist per-project CSV export), same mapping wizard.
- Dry-run preview (counts per area, unmapped items) before commit; import is idempotent via source ids.

## 13. Committed listener reports

Generated on-device from TaskTransition + HealthSnapshot + MeasurableResult scoring. Template-based narrative (Tier 0), optional Tier 1/3 phrasing. Delivery: user's Gmail send scope (from the user's own address) or share sheet (WhatsApp/SMS). Always preview-before-send. Optional capture attachments per listener setting.

## 14. Pricing & feedback (revised v1.4 — app is FREE)

**Saara is completely free.** No subscription, no ads, no in-app purchases, no accounts. All features (unlimited areas, listeners, captures up to the user's own storage cap, all AI tiers, voice, imports) are available to every user. This is a core part of the trust story: free + zero data collection + local-first.

**Feedback channel:** Settings → "Send feedback to the maker" opens the user's own email app via a `mailto:` intent pre-addressed to **veera@realmaya.com**, with an optional pre-filled template (app version, Android/iOS version, free-text). Attachments (e.g. a screenshot) added by the user in their mail app. Nothing is sent automatically; no analytics, crash-reporting, or telemetry SDKs are included — if the user reports nothing, Realmaya receives nothing. A second entry point appears once, ~2 weeks after first use, as a card in the evening review ("Enjoying Saara? Tell Veera — or rate on the Play Store"), dismissible forever.

**Store listing note:** mark app as Free; Data Safety form remains "No data collected" (email feedback is user-initiated via their own mail client and is not app data collection).

## 15. Content, legal, compliance

- Home quotes: public-domain or properly attributed integrity/completion quotes only. **Do NOT reproduce Landmark Worldwide proprietary language or imply affiliation.**
- Privacy policy (hosted at realmaya.com/saara or dedicated domain): states zero data collection; contacts/health/location processed on-device only; lists the two OAuth scopes' purposes; Data Safety form (Play) & Privacy Nutrition Label (iOS) accordingly — "No data collected."
- Permissions requested just-in-time with rationale screens: contacts (participant matching), location (foreground only: travel-time + navigation deep links + geofence arrival prompts), camera/mic (captures), notifications, health.
- India DPDP posture: no processing by Realmaya = minimal obligations; still document it.

## 16. Capture limits & user-cloud archive

- Video ≤ 180 s (countdown ring, auto-stop), 720p H.265 default / 1080p toggle; audio ≤ 600 s AAC; text unlimited.
- Storage meter per area; user cap (default 2 GB); approaching-cap prompt appears in evening review only; **never auto-delete**.
- Archive to user's own cloud: Google Drive via `drive.file` scope (app-created folder `Saara Captures/<Area>/...`), iCloud Drive on iOS, or any location via document picker. Manual (long-press → archive) and opt-in auto-archive (older than N days). Thumbnails + metadata stay local; timeline/compare unaffected; stream back on demand.

## 17. Build phases

- **Phase 1 (MVP, Android-first):** DB + state machine, parser, task card, home timeline, morning/evening flows, local notifications, recurring engine, Todoist import, share-target (text), settings, feedback mailto.
- **Phase 2:** Google Calendar two-way sync, contacts participants, capture system (all three types, limits), area pages + measurable results (manual & task-log verification), image share-target OCR.
- **Phase 3:** Health Connect/HealthKit verification, listeners + Gmail send, Drive archive, compare view, geofencing/travel-time, on-device AI (Tier 1).
- **Phase 4:** iOS release, Tier 2 export + Tier 3 BYOK, escalation rules, weekly report polish.

## 18. Developer testing (Android, on your phone)

1. Enable Developer Options → USB debugging; `flutter run` for hot-reload on device.
2. `flutter build apk --release` → install APK directly for offline/day-rhythm testing (notifications behave realistically only in release/profile builds — test the 07:00/21:00 cycle over several real days; also test with battery optimization ON, and add the manufacturer-specific autostart exemption prompt, critical on Xiaomi/Oppo/Vivo common in India).
3. Play Console → Internal testing track under Realmaya account (up to 100 testers, store-signed build).
4. Google OAuth: create OAuth client (Android type, SHA-1 of both debug & release keys), add yourself as test user on the consent screen — Calendar works pre-verification for test users.
5. Definition of done per phase: all flows operable airplane-mode (except OAuth/sync), zero network calls observed except user-initiated Google/Todoist/LLM traffic (verify with an on-device packet inspector).


---

## 19. Voice interface (added v1.1)

**Principle:** voice is an input/output layer over the existing deterministic core — no separate intelligence path.

### 19.1 Voice input
- Mic button on Home and on the task card. Speech-to-text via platform engines with on-device recognition preferred: Android `SpeechRecognizer` (prefer on-device model where supported), iOS `SFSpeechRecognizer` with `requiresOnDeviceRecognition = true` when available (fallback to server recognition only with explicit user consent toggle, default OFF to preserve the privacy claim).
- Transcript → existing pipeline: deterministic parser (Section 5) → Tier 1 on-device model if confidence < 0.6 and hardware supports.
- Locale: default to device locale; support en-IN explicitly; Hindi/regional locales as the platform recognizers allow (surface availability in Settings).

### 19.2 Intent grammar (deterministic command router)
Match transcribed text against intent patterns BEFORE task-creation parsing:
```
whats_next        : "what's next" | "next task" | "what do I have next"
day_summary       : "summary of my day" | "how did I do" | "how's my day"
open_day          : "open my day" | "morning brief"
close_day         : "close my day" | "evening review"
area_status       : "how is my <area>" | "<area> score"
complete_task     : "mark <task> done" | "completed <task>"
start_task        : "start <task>"
reschedule_task   : "move <task> to <datetime>"
navigate_task     : "navigate to <task>"        → Maps deep link
create_task       : (default fallback → Section 5 parser)
```
`<task>` resolved by fuzzy match against today's/open tasks; ambiguity → spoken + visual disambiguation chips. All intents map to existing queries/state transitions; no new business logic.

### 19.3 Voice output
- TTS via Android TextToSpeech / iOS AVSpeechSynthesizer (system voices; user-selectable voice + rate in Settings).
- Speakable renditions: morning brief, evening summary, whats_next, area_status. Settings toggle: "Saara speaks replies" (ON when interaction began by voice, otherwise per setting).
- Keep spoken lines short, template-based (Tier 0); Tier 1 may rephrase when active.

### 19.4 Hands-free via system assistants (no custom wake word in v1)
- Android App Actions / Shortcuts: "add a task in Saara", "what's next in Saara", "open my day in Saara" → deep-link into corresponding voice flow.
- iOS Siri Shortcuts + App Intents: donate intents for the same commands; user can create "Hey Siri, Saara next".
- Explicit non-goal v1: continuous custom hotword listening (battery/privacy/review cost). Revisit post-launch.

### 19.5 Permissions & privacy
- RECORD_AUDIO / mic permission requested just-in-time on first voice use, with rationale screen; same permission already covers audio captures.
- Privacy policy addition: voice processed on-device where supported; no audio stored unless the user records a capture.
- Phase placement: 19.1–19.3 in Phase 2; 19.4 in Phase 3.

---

## 20. UI design system (added v1.2)

**Language:** Material Design 3 (Material You), Flutter `useMaterial3: true`. Card-first layout throughout.

### 20.1 Core patterns
- **Cards everywhere:** every entity renders as a card — task card (timeline), area card (with progress ring), capture card (thumbnail + type badge), listener card, report card. Elevated/filled card variants per M3 spec; consistent corner radius (12–16 dp), comfortable touch targets (≥48 dp).
- **Layout:** Home = vertical timeline of task/event cards grouped by time-of-day headers; Areas = 2-column card grid; bottom NavigationBar (M3): Today · Areas · Captures · Saara (agent/chat+voice) · Settings. FAB (expanding) on Today: speak/type task · capture · quick-add.
- **Color:** M3 dynamic color from the user's wallpaper (Android 12+) with a Saara brand seed color fallback (suggest deep teal — calm, trustworthy; final choice yours). Full light/dark theme support; respects system setting.
- **Typography:** M3 type scale, default Roboto/system; large-title day headers, generous whitespace. Support system font scaling (accessibility).
- **Motion:** standard M3 transitions; task completion gets a single satisfying check animation (no confetti spam); hold-to-record uses WhatsApp-style ring affordances (already specced §7, §16).
- **iOS note:** keep Material 3 on both platforms for one consistent brand (acceptable and common), with platform-adaptive details: iOS-style back-swipe, share sheet, haptics via platform APIs.
- **Accessibility:** semantic labels on all controls (works with TalkBack/VoiceOver — pairs with §19 voice), min contrast per M3, dynamic type tested to 200%.

### 20.2 Saara identity: icon & avatar
- **Saara avatar picker (Settings → "Your Saara"):** user chooses how Saara appears — a set of 8–12 bundled avatar options (abstract mark variants, warm geometric faces, initial-letter monogram, minimal orb) + color tint. Avatar appears in: morning/evening brief header, agent tab, voice-listening overlay (pulsing while listening — M3 style), notifications (large icon), and report headers ("Saara, for <user>").
- All avatar assets bundled locally (no downloads); vector (SVG→Flutter) so they tint with the theme.
- Optional user-name greeting ("Good morning, Aruna") — name stored locally from onboarding, editable.
- **App icon:** single distinct launcher icon (adaptive icon on Android, all iOS sizes) — the brand mark, independent of the user's chosen in-app avatar. Keep the mark original (no resemblance to existing assistant logos).
- **Voice + avatar together:** when Saara speaks (§19.3), the avatar animates subtly (breathing/pulse), giving the agent presence without skeuomorphic gimmicks.

### 20.3 Onboarding (first run)
1. Welcome + integrity quote → 2. Name + choose your Saara avatar → 3. Pick starter Areas (chips: Health, Family, Finance, Work, Relationships, +custom) — each picked chip flips to a "name it your way" field with playful placeholder examples ("Diehard", "Sweetmango", "Money Mountain"); skipping keeps the default name → 4. Set morning/evening times → 5. Optional: connect Google Calendar / import Todoist / enable voice — each skippable. Total ≤ 90 seconds to first task.
