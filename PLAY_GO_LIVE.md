# Saara — Play Store go-live pack

Everything you need to paste into the Play Console + a hostable privacy policy.
Written for the **current build (BYOK AI, local-first, no background location)**.
See the last section for what changes if you adopt **managed AI** (Realmaya pays
the API meter).

> Not legal advice — review with your own eyes (and counsel if you can) before
> publishing. Fill the **[bracketed]** bits.

---

## 0. Verified build facts (as of v1.0.50+51)

| Fact | Value | Play requirement | OK? |
|---|---|---|---|
| Application ID | `com.realmaya.saara` | unique, final | ✅ |
| Version | `1.0.50+51` (versionCode 51) | must increase each upload | ✅ |
| `targetSdkVersion` | **36** | ≥ 35 for new apps | ✅ |
| `minSdkVersion` | 26 | your choice (Health Connect needs 26) | ✅ |
| Signing | release keystore via `key.properties` + **Play App Signing** | signed release | ✅ |
| Background location | **not declared** | avoids the hard review | ✅ |
| CAMERA permission | **not declared** (intent-based capture) | fewer justifications | ✅ |
| Artifact | `build/app/outputs/bundle/release/app-release.aab` (~85 MB) | AAB, not APK | ✅ |

Rebuild the uploadable artifact any time with: `flutter build appbundle --release`.

---

## 1. Data Safety form (Play Console → App content → Data safety)

**Does your app collect or share any user data?** → **Yes**
(Realmaya operates no backend and stores nothing on its servers, but the app
*does transmit* some data off the device at the user's direction — to Google and
to the user's chosen AI provider — which Google counts as "shared".)

**Is all data encrypted in transit?** → **Yes** (all endpoints are HTTPS).
**Do you provide a way to request deletion?** → **Yes** (uninstalling removes all
local data; the user controls their Google/AI accounts directly).

Declare these data types. For each: **Collected = No** (nothing goes to Realmaya),
**Shared = Yes** (to the third party named), **Processed ephemerally**, **Optional**,
purpose **App functionality**.

| Data type | Shared with | When |
|---|---|---|
| **App activity** — your tasks/events text | Google (Tasks/Calendar); your AI provider | Only if you enable Google sync / use AI |
| **Photos/videos** — media you capture against a task | **Not shared** by default — stored on-device; a **photo** is sent to your AI provider only when you tap "Extract with AI" | Capture is local; export is user-initiated |
| **Files & docs** — screenshots/images you extract | Your AI provider | Only when you tap "Extract with AI" |
| **Google Drive** | **Not accessed** — the Drive picker and its `drive.readonly` scope are **off** in this release; Drive links are plain text the user pastes | — |
| **Health & fitness** — steps/sleep/weight | **Not shared** — read on-device from Health Connect, never leaves the device | — |
| **Contacts** | **Not shared** — matched on-device for participants, never uploaded | — |
| **Audio** — voice dictation **and** recorded audio notes | Voice dictation uses your device's speech service (may be Google); **recorded audio-note captures are not shared** (on-device only) | Dictation while holding the mic; captures stay local |
| **Location (approx/precise)** | **Not shared** — used on-device to geocode a task's place | Only when you type a place |

> **"Export all my data"** (Settings → Data) builds a local `.zip` (all tables + capture media) and hands it to Android's share sheet. Nothing is uploaded — the file only leaves the device if *you* pick a destination. This is user-initiated data portability, not collection/sharing by the app.

Key honest points to select:
- Realmaya itself **collects nothing** (no account, no server).
- Data is **shared** only with **Google** (your own account) and your **AI
  provider** (your own key), and only for features you switch on.

---

## 2. Permissions — declarations / justifications

| Permission | Why | Notes |
|---|---|---|
| INTERNET | Google sync + your AI provider | — |
| POST_NOTIFICATIONS | Morning/evening + per-task reminders | Requested just-in-time |
| SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM | Fire reminders at the exact time | Falls back to inexact if denied |
| RECEIVE_BOOT_COMPLETED | Re-arm scheduled reminders after reboot | — |
| READ_CONTACTS | On-device participant matching | Never uploaded |
| RECORD_AUDIO | Voice → task (speech-to-text) **and** audio-note captures | On-device; captures stored locally |
| ACCESS_FINE/COARSE_LOCATION | Geocode a task's place (foreground only) | **No background location in this release** |

> **No `CAMERA` permission is declared.** Photo/video capture uses the system
> camera app via `image_picker`'s intent (`ACTION_IMAGE_CAPTURE` /
> `ACTION_VIDEO_CAPTURE`), which needs no CAMERA permission — one less thing to
> justify. Media plays back on-device (`video_player` / `audioplayers`).
| Health Connect (READ_STEPS/SLEEP/WEIGHT/…) | Auto-score health results | Read-only; see §3 |

**No `ACCESS_BACKGROUND_LOCATION`** in this build (arrival geofencing is off via
`kGeofenceEnabled=false`), so you **avoid the background-location review** entirely.

---

## 3. Health Connect declaration (Play Console → App content → Health)

- **Data types requested:** Steps, Sleep, Weight (read-only).
- **How used:** to automatically score the user's own health goals in-app.
- **Not shared, not sold, stays on device.** Complete the Health Apps
  declaration form; you'll likely need a short justification + a demo showing the
  read-only, in-app use.

---

## 4. Google OAuth (before production)

**Decision taken: the restricted Drive scope is OFF for launch.**
`kDrivePickerEnabled = false` in `lib/services/google/google_config.dart`
removes `drive.readonly` from the requested scopes and hides the Drive picker.
Users paste a Drive link instead — that needs no scope at all.

Why it matters:

| Scope | Google tier | Verification cost |
|---|---|---|
| `tasks`, `calendar.events` | **Sensitive** | Brand review + demo video |
| ~~`drive.readonly`~~ (off) | **Restricted** | **+ CASA security assessment** (weeks + cost) |

Staying **sensitive-only** keeps verification to the light path. Flip the flag
and re-add the scope after verification if you want the picker back.

> **Decided: Saara will not use the Drive API at all — now or later.** Media
> archiving is a plain **folder move** to a location the user picks (external
> drive, NAS, or a desktop-synced cloud folder), which needs no OAuth scope and
> therefore can never pull the app into a CASA security assessment. This keeps
> the requested scopes permanently at *sensitive-only*.

Remaining steps:
- Move the OAuth consent screen from **Testing → In production / Published**,
  and complete the (sensitive-scope) verification: app details, a demo video of
  the sync flow, and the hosted privacy policy URL.
- Register the **Play App Signing SHA-1** on the production Android OAuth
  client (you already did this for testing).
- **Desktop** uses a separate *Desktop app* OAuth client + loopback/PKCE flow
  (see `DESKTOP_BUILD.md`). Not part of the Play submission.

---

## 5. Store listing essentials

- **Privacy policy URL** — host §6 below (GitHub Pages / your site) and paste it.
- **App category:** Productivity.
- **Content rating:** complete the questionnaire (no objectionable content).
- **Target audience:** adults (not designed for children).
- **Ads:** none. **In-app purchases:** none (this release).

---

## 6. Privacy policy — SUPERSEDED

> ⚠️ **Do not use the text below.** It was written at v1.0.50 and still mentions
> the Google Drive picker, which is permanently disabled
> (`kDrivePickerEnabled = false`) — publishing it would claim a scope Saara does
> not request and does not want.
>
> **Use `docs/privacy.html` instead** (ready to host), with the Data safety
> answers in `docs/PLAY_DATA_SAFETY.md`.

<details>
<summary>Superseded v1.0.50 draft (kept for history)</summary>

> **Saara — Privacy Policy**
> Last updated: **[DATE]**
>
> Saara ("the app") is provided by **[Realmaya / legal entity]** ("we", "us").
> Saara is a **local-first** personal integrity and productivity app: your data
> lives **on your device**, in an encrypted database. **We do not operate a
> server that collects or stores your personal data, and we have no account
> system.**
>
> **What stays on your device**
> Your tasks, events, areas, measurable results, integrity history, captured
> notes/photos/audio/video, and settings are stored locally and encrypted.
> Health data read from Health Connect and contacts used for participants are
> processed **on your device only** and are never uploaded to us. You can export
> everything to a local file at any time (Settings → Export all my data); that
> file is created on your device and only leaves it if you choose to share it.
>
> **What the app sends, and to whom (only for features you enable)**
> - **Google (your own account):** if you turn on sync, your tasks and calendar
>   events are sent directly from your device to **Google Tasks / Google
>   Calendar**, and — if you use the Drive picker — file names/links are read
>   from **Google Drive**. This is governed by Google's privacy policy.
> - **Your AI provider (your own key):** if you add an AI key and use an AI
>   feature, the relevant text and/or image is sent directly from your device to
>   the provider you chose (**Google Gemini** or **Anthropic**). We never receive
>   it. Usage is billed to your own provider account and governed by their
>   policies — review them.
> - **Speech recognition:** voice dictation uses your device's speech service,
>   which on many devices is provided by Google.
>
> **What we (Realmaya) receive:** nothing about your tasks, health, contacts, or
> AI content. We run no analytics SDK and no ad SDK in this release.
>
> **Permissions** are requested only when needed and used solely for the feature
> described (notifications, reminders, contacts matching, microphone for voice,
> camera for capture, foreground location to geocode a place, Health Connect to
> score health goals).
>
> **Data retention & deletion:** everything is on your device. **Uninstalling the
> app deletes all local data.** You control your Google and AI-provider data
> directly in those accounts.
>
> **Children:** Saara is not directed to children under 13.
>
> **Changes:** we'll update this policy here and change the date above.
>
> **Contact:** [email].

</details>

---

## 7. Release notes (internal → production)

> Saara turns intentions into a track record. Capture tasks by typing, pasting,
> voice, or a photo; keep them in sync with Google Tasks & Calendar; measure real
> results (including from Health Connect); and watch your reliability climb from
> Beginner to Masterful. Everything stays on your device — bring your own AI key
> for the smart features.

**Full feature set at launch** (for the store description / demo video):

- **Tasks & events** — type, paste, dictate, or photograph them; two-way Google
  Tasks + Calendar sync; recurring events; per-task reminders
- **Areas** (max 10) with measurable results, including Health Connect
- **Integrity scoring** — binary kept/committed on a 6-tier reliability ladder,
  now reported **per time scale** (today / week / month / all-time)
- **Meeting agendas** — an event can hold timed action items that auto-chain
  back-to-back, plus a hands-free **Start agenda** runner with a live timer
- **Task timer** — live stopwatch on start, flags overrun against the plan
- **Captures** — text, photo, audio, and video recorded against any task
- **Search** — free text plus `has:` filters and natural dates, with sorting
- **Import** — Excel/CSV (incl. Todoist project exports) and Markdown outlines
- **Export all my data** — a local zip of every table plus capture media
- **Saara AI (bring your own key)** — chat that acts, and image/text extraction

**Free at launch.** No ads, no in-app purchases, no subscription. Monetisation
(a managed-AI "Pro" tier) is deliberately deferred until real usage validates it
— see §9.

---

## 8. RELEASE RUNBOOK — do these in order

> Two things have **waiting periods** (OAuth verification; the 12-tester/14-day
> closed test). Start both as early as possible so they run *in parallel* with
> the paperwork instead of after it.

### Step 0 — Confirm the build (you + me)
- [ ] Test the current build on **phone and desktop**; tell me anything wrong.
- [ ] Decide the public version name. It's `1.0.83` today, which reads like a
      long beta — say the word and I'll set **`version: 1.0.0+84`** for launch
      (the *name* can go down; only `versionCode` must keep increasing).
- [ ] I rebuild, verify `flutter analyze` is clean, and confirm the AAB is
      release-signed (`CN=Realmaya Private Limited`, not a debug key).

### Step 1 — Host the privacy policy *(blocks Play **and** OAuth)*
- [ ] Fill the `[bracketed]` fields in §6 and publish it at a public URL.
      GitHub Pages is free: new repo → `index.md` with the §6 text →
      Settings → Pages → deploy from `main`.
- [ ] Keep the URL — you need it twice.

### Step 2 — Play Console account
- [ ] Register (one-time **$25**) and complete identity verification.
      *A personal account may then require a closed test with **≥12 testers for
      14 days** before Production — Step 5.*
- [ ] **Create app**: name **Saara**, English, **App**, **Free**.

### Step 3 — Upload to Internal testing *(do this first — it's instant)*
- [ ] Release → Testing → **Internal testing** → **Create new release**.
- [ ] Accept **Play App Signing** (recommended — Google holds the signing key).
- [ ] Upload `build\app\outputs\bundle\release\app-release.aab`.
- [ ] Release notes: §7.
- [ ] Add yourself + testers by email → share the opt-in link → install and
      smoke-test **from the Play build** (not the sideloaded one).
- [ ] **Copy the Play App Signing SHA-1** (Release → Setup → App signing) and
      add it to your **Android OAuth client** in Google Cloud Console —
      otherwise Google sign-in fails for everyone who installs from Play.

### Step 4 — App content (every item must go green)
- [ ] **Privacy policy** → the Step 1 URL
- [ ] **Data safety** → answers in §1
- [ ] **Health apps declaration** → §3 (Steps/Sleep/Weight, read-only, on-device)
- [ ] **Content rating** questionnaire · **Target audience**: adults
- [ ] **Ads**: No · **In-app purchases**: No · **Government app**: No · **News**: No
- [ ] Store listing: short + full description (§7), app icon 512×512, feature
      graphic 1024×500, **≥2 phone screenshots** (Today, Areas, Progress, Saara
      chat, an event agenda)

### Step 5 — OAuth verification *(start now; it waits on Google)*
- [ ] Cloud Console → **OAuth consent screen** → **External** → **Publish app**
- [ ] Submit for verification: app details, the privacy-policy URL, and a short
      **demo video** of the Google sync flow
- [ ] Scopes are **sensitive-only** (`tasks`, `calendar.events`) — the light
      path. Do **not** add Drive; see the box in §4.

### Step 6 — Closed testing *(only if your account requires it)*
- [ ] Promote the same build to **Closed testing**, recruit **12 testers**, keep
      them opted in for **14 continuous days**.

### Step 7 — Go live
- [ ] Production → **Create release** → promote the same AAB
- [ ] Rollout percentage (20% first is sensible) → **Start rollout**
- [ ] Google review typically takes a few days for a first submission.

### After launch
- [ ] Watch Play Console → **Quality → Crashes & ANRs** (Saara sends no
      telemetry of its own, so this is your only signal).
- [ ] Ship updates by bumping `version:` and repeating Step 3 → Step 7.

---

## 8b. Older walkthrough (superseded by the runbook above)

**A. One-time account + app shell**
1. Pay the **$25** Google Play developer registration (if not already) and finish identity verification. New personal accounts may need **closed testing with ≥12 testers for 14 days** before you can promote to production — factor this in.
2. Play Console → **Create app** → name "Saara", Productivity, Free, declarations.

**B. Upload the build**
3. **Release → Testing → Internal testing → Create release.** Let Play enable **App Signing**. Upload `app-release.aab`. Add yourself as a tester and install via the opt-in link — smoke-test AI (Check available models), captures, export, Google sync.
4. When happy, promote the same build up the tracks (Internal → Closed → Production).

**C. Store presence** (Grow → Store listing / Store settings)
5. App icon (512×512), feature graphic (1024×500), **≥2 phone screenshots** (grab from your device: Today, Areas, Progress, Saara chat, a task with captures).
6. Short + full description (adapt §7). Category: Productivity. Contact email.

**D. App content (left nav — every item must be green)**
7. **Privacy policy URL** — host §6 (GitHub Pages works) and paste.
8. **Data safety** — enter per §1.
9. **Health** declaration — per §3 (Steps/Sleep/Weight, read-only, on-device). This one often needs a short video showing in-app read-only use.
10. **Content rating** questionnaire; **Target audience** = adults; **Ads** = No; **Government app** = No; **News** = No.

**E. Google OAuth** (Cloud Console, before production traffic)
11. Move the consent screen to **In production**; ensure the **Play App Signing SHA-1** is on the production Android OAuth client.
12. **Drive `drive.readonly` is a restricted scope** → may trigger Google verification. If it stalls launch, **drop the Drive picker for v1** (paste-a-link still works) and add it back post-verification. See §4.

**F. Roll out**
13. Production → Create release → same AAB → review release notes (§7) → **Start rollout**. First review typically takes a few days.

> **Fastest safe path to "live":** Internal testing today (instant, private) → fix anything → Closed testing to satisfy the 12-tester/14-day rule if your account requires it → Production. Health + Drive are the two items most likely to add review time; you can launch **without** Drive scope and **with** Health if you complete its form.

---

## 9. Monetisation — deliberately deferred (decided)

**Launch free. Revisit pricing once real usage exists.** The reasoning:

- The headline feature (AI) is **bring-your-own-key**, and that onboarding is
  the roughest part of the app. Charging before it "just works" invites refunds.
- **Zero external users so far.** Retention is the signal worth having before
  pricing — a user still active in month three is worth more than any early fee.
- **Cross-device is half-done:** tasks/events sync, but areas, integrity scores
  and captures don't. Paid multi-device implies those converge.

**Voluntary contributions** are fine as a gesture (an external Razorpay/Ko-fi
link in Settings — *never* Google Play Billing), but only if **unconditional**:
the moment a contribution unlocks anything, Play treats it as a digital purchase
and Play Billing becomes mandatory. Note money received by Realmaya Pvt Ltd is
**business income**, not a charitable donation — confirm GST/tax treatment with
a CA before publishing any payment link. Realistic conversion is 0.1–1%, so it
funds goodwill, not an API meter.

**The likely eventual shape:**

| Tier | Contents | Principle |
|---|---|---|
| **Free** | Everything local + BYOK AI | Privacy intact, no server |
| **Pro** (subscription) | AI included (no key), encrypted cross-device sync, desktop | Needs the proxy below — disclosed honestly |

Pro is precisely the two things that require a server anyway, so the free tier
stays purely local-first.

---

## 10. If you adopt "managed AI" (Realmaya covers the API meter)

You floated covering the AI cost so users don't need a key. Honest implications:

- **It requires a backend.** You can't ship your API key in the app (it's
  extractable and would be drained). All AI calls must route
  **device → your server (holds the key, meters usage) → provider**. That's a new
  component (a serverless proxy + per-user metering + abuse limits).
- **It changes this privacy policy & Data Safety:** AI content would then pass
  **through Realmaya's server** — so "we receive nothing" is no longer true for
  AI. You'd disclose that Realmaya processes AI request content (even if
  ephemerally) and update the Data Safety "collected/shared" answers.
- **Cost control is mandatory:** cap per-user AI actions and use a cheap model
  (Haiku / Gemini Flash), or a few heavy users exceed any revenue.

**Recommendation:** **launch now with BYOK** (this build is ready, and the
deterministic parser works with no key at all), then add managed AI as a
**fast-follow** once the proxy is built and demand is validated. That avoids a
launch delay, infra cost before validation, and a more complex privacy review.
When you're ready, I can build the proxy + metering and the in-app "AI included"
switch.
