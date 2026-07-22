# Phase 3 roadmap & setup

Phase 3 (§17) is large and, unlike Phases 1–2, most of it depends on **external
setup you control** — Google Cloud OAuth, Health Connect, device permissions.
This doc sequences the work and lists exactly what each piece needs from you so
we don't get blocked mid-build.

Already shipped from Phase 3's spirit (self-contained, no setup):
- ✅ **Committed listeners** — add/manage, on-device report from the ledger,
  **preview + send via the share sheet** (§13). *Gmail-from-your-address* is the
  only listener piece still needing OAuth (below).

---

## A. Health Connect / HealthKit verification (§10) — *needs device setup*

Auto-score measurable results with `verification = health_source` (steps, active
minutes, sleep, weight).

- **Plugin:** `health`.
- **Android needs:** Health Connect app installed on the phone; a
  `HealthConnectPermission` rationale screen; read-only permissions requested
  just-in-time; a `health_permissions` declaration in the manifest; **Play Data
  Safety + a Health apps declaration form** (Google reviews health-data use).
- **What I build:** a "Health-verified" metric type in the result form, a daily
  `HealthSnapshot` pull (WorkManager), and auto-scoring into the same progress
  path measurable results already use.
- **From you:** confirm the phone has Health Connect; approve the health-data
  declaration in Play Console when we submit.

## B. Gmail-send for listener reports (§13) — *needs Google Cloud OAuth*

Send the report from the **user's own Gmail address** instead of the share sheet.

- **Scopes:** `gmail.send` (sensitive → verification), requested incrementally.
- **Needs:** a **Google Cloud project**, OAuth consent screen, an Android OAuth
  client (SHA-1 of debug + upload keys), you added as a **test user**, and a
  published **privacy policy** (already required for the store).
- **What I build:** `google_sign_in` + PKCE, a Gmail REST `messages.send` call
  (device→Google direct), and a "Send via Gmail" option on the listener.
- **From you:** create the Cloud project + consent screen (I'll give exact
  steps), share the client ID.

## C. Google Drive archive for captures (§16) — *needs Google Cloud OAuth*

Archive capture media to the user's own Drive (`Saara Captures/<Area>/…`).

- **Scope:** `drive.file`. Same Cloud-project/consent prerequisites as (B).
- **Depends on:** the capture system (Phase 2) existing first.
- **What I build:** manual long-press → archive, opt-in auto-archive older than
  N days; thumbnails/metadata stay local.

## D. Geofencing & travel-time (§8) — *needs location permission*

"Leave by" alerts for located tasks; arrival prompts.

- **Plugins:** `geolocator` + platform geofence; **foreground location only**
  (no background tracking in v1, per §8).
- **Needs:** location permission rationale screen; Play **location-use
  declaration**.
- **What I build:** last-known-location travel estimate → reminder offset; a
  foreground geofence registered when a located task is imminent.

## E. On-device AI, Tier 1 (§6) — *device-dependent, no account setup*

Gemini Nano (Android AICore/ML Kit GenAI) / Apple Foundation Models to (a) clean
up messy conversational entry, (b) split brain-dumps, (c) friendlier brief lines.

- **Needs:** a platform channel to ML Kit GenAI; **only runs on supported
  hardware** (Pixel 8+/high-end) — graceful fallback is the default path.
- **What I build:** startup capability detection (the Settings line already
  says "Not supported" until this lands), and a Tier-1 hook the parser already
  exposes for confidence < 0.6.
- **From you:** nothing account-wise; test on a supported device if you have one.

---

## Suggested order

1. **Health (A)** — highest user value, self-contained on-device once Health
   Connect is present; makes the measurable-result rings verify automatically.
2. **Gmail + Drive (B, C)** — do together since they share the Cloud project /
   consent screen. Requires the capture system for Drive.
3. **Geofencing (D)** — smaller, self-contained once location permission is in.
4. **On-device AI (E)** — last; hardware-gated and a pure enhancement.

Tell me which to start and I'll either build it (if self-contained) or hand you
the precise Google Cloud / Play declaration steps first.
