# Saara — Play store listing pack

Copy-paste content for the Play Console listing, a click-by-click for the Data
Safety form (current build), and a screenshot shot-list. Reflects
`1.4.16+156` (BYOK AI, local-first, no Drive, no background location).

---

## 1. Store listing copy

### App name
`Saara`

### Short description (max 80 chars)
> Local-first tasks with honest scoring, Google sync, and bring-your-own AI.

*(72 chars. Alternate: "Keep your word — local-first tasks, honest scoring, sync, your-own-key AI." = 72)*

### Full description (max 4000 chars)

> **Saara turns intentions into a track record — privately.**
>
> Saara is a local-first personal integrity and productivity app. Your tasks,
> events, notes and history live in an **encrypted database on your device**.
> There is no Saara account and no Saara server — we collect nothing.
>
> **Keep your word, and see it.**
> Every task you commit to becomes part of an honest, tamper-evident record.
> Saara scores what you actually did — not what you edited afterward — and shows
> your reliability climbing a six-tier ladder from Beginner to Masterful, per day,
> week, month, and all-time.
>
> **Capture tasks any way you like.**
> Type, paste, dictate by voice, or snap a photo and let AI pull out the details.
> Give a task a time and duration and it becomes a calendar event; leave it open
> and it's a simple to-do.
>
> **Sync with Google — directly, no middleman.**
> Two-way sync with Google Tasks and Google Calendar happens device-to-Google
> from your own account. Recurring events (with an end date), Google Meet links,
> reschedules and deletes all stay in step.
>
> **Organize by life areas.**
> Group work into up to ten areas and track measurable results — including from
> Health Connect (steps, sleep, weight) scored automatically on-device.
>
> **Ask Saara.**
> A conversational assistant that both acts and finds: "create a daily 7:30 stand-
> up under Work", or "what's overdue in Health this week?" — answered with your
> actual tasks. Powered by your own AI key (bring your own); the deterministic
> core works with no key at all.
>
> **More that helps day to day.**
> A spreadsheet-style filter on your task list (status, type, date range, area,
> source); call or WhatsApp a task's participant in one tap; capture text, photo,
> audio or video against any task; import from Excel/CSV or a Markdown outline;
> export everything to a local zip.
>
> **Sync between your own devices — without the cloud.**
> Move your full record (tasks, history, areas) between your phone and desktop
> through an encrypted file you control. It never passes through Google or any
> server.
>
> **Privacy by design.**
> - No Saara account, no Saara server, no telemetry, no ads.
> - Data is shared only with services you switch on — your own Google account,
>   and your own AI provider (your key) — and only for those features.
> - Health data and contacts are processed on your device and never uploaded to
>   us.
> - Encrypted on-device storage; uninstalling deletes all local data.
>
> Free, with no in-app purchases.

### "What's new" for this release (max 500 chars)
> • Google sync keeps a task's exact time (no more midnight surprises)
> • Recurring events reach Google Calendar; series can have an end date
> • Tasks: a spreadsheet-style header to sort & filter (status, type, date range, area, source)
> • Ask Saara to find tasks in plain language
> • Create tasks with recurrence by voice/chat, then tweak them
> • Call or WhatsApp a task's participant in one tap

---

## 2. Data Safety — click-by-click (Play Console → App content → Data safety)

Saara collects nothing to Realmaya, but the app *transmits* some data off the
device at the user's direction (to Google and to the user's AI provider), which
Google counts as **shared**.

**Overview screen**
- Does your app collect or share any of the required user data types? → **Yes**
- Is all of the user data encrypted in transit? → **Yes**
- Do you provide a way for users to request that their data is deleted? → **Yes**
  (uninstalling removes all local data; the user controls their Google/AI accounts)

**For every data type below, answer the same way:**
- Collected? → **No** (nothing goes to Realmaya)
- Shared? → **Yes** (to the third party named)
- Processing: **ephemeral** where offered · Optional · Purpose: **App functionality**

| Data type (Play category) | Share? | With whom / note |
|---|---|---|
| App activity → your task/event **text** | **Shared** | Google (Tasks/Calendar) and your AI provider — only if you enable sync / use AI |
| Photos and videos | **Shared** | Your **AI provider**, and only when you tap "Extract with AI". Captures are otherwise on-device |
| Files and docs (images you extract) | **Shared** | Your AI provider, only on "Extract with AI" |
| Health and fitness | **Not shared** | Read on-device from Health Connect; never leaves the device |
| Contacts | **Not shared** | Matched on-device for participants; an optional phone number is stored **locally** and synced only between your own devices via an encrypted file — never to Google or Realmaya |
| Audio (voice dictation) | **Shared** | Uses the device's speech service (often Google). Recorded audio-note captures are **not shared** (on-device) |
| Location (approx/precise) | **Not shared** | Used on-device to geocode a task's place, only when you type one |

> Do **not** declare Google Drive (the picker/scope is off) or background
> location (off in this build).

---

## 3. Screenshots — shot-list (Play needs ≥2; provide 5)

Portrait phone screenshots, real content, one theme (light reads cleaner in the
store). Grab from your device or an emulator.

| # | Screen | What to show |
|---|---|---|
| 1 | **Today** | The reliability ladder + a couple of real tasks — the "keep your word" hook |
| 2 | **Tasks** | The spreadsheet-style **header-row filters** (Title · Type · Date · Area · Status · Source) over a populated list |
| 3 | **Areas** | The area cards (and the Unclassified tile) — organization by life area |
| 4 | **Progress** | The integrity wheel / score across time scales |
| 5 | **Saara** | A natural-language **find** result, or a "create" confirm card — the AI that acts |

Also needed:
- **App icon** 512×512 (PNG, from `assets/icon/`).
- **Feature graphic** 1024×500 (a simple branded banner — tagline over the brand red).

Framing tips: no personal phone numbers/emails visible; status bar clean; leave a
little breathing room — the store crops slightly.
