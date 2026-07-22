# Play Console — Data safety answers (v1.0.107+108)

Fill the **Data safety** form (App content → Data safety) with these. They match
the verified build: no backend, no analytics/ads SDK, BYOK AI, scopes limited to
`tasks` + `calendar.events`, no background location, no Drive.

> Play's definition of **"collected"** = transmitted off the device *to you or a
> third party you integrate*. Data that only ever sits on the device is **not**
> collected. Data the user sends to a service **they** chose and pay for is
> "transferred" — declare it where the form asks about third parties.

---

## 1. Overview questions

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** — declare the Google-synced items + optional AI text (see §2) |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (HTTPS/TLS to Google and the AI provider) |
| Do you provide a way for users to request that their data is deleted? | **Yes** — in-app delete + uninstall removes all local data; no server copy exists |

---

## 2. Data types to declare

Only these leave the device, and only when the user turns the feature on.

### Personal info → Other (task/event content)
- **Collected:** Yes · **Shared:** Yes (with Google, at the user's direction)
- **Processed ephemerally?** No
- **Required or optional?** **Optional** — only if the user connects Google
- **Purpose:** App functionality
- Titles, dates, notes, locations and meeting links of synced tasks/events go to
  the user's own Google Tasks / Calendar account.

### App activity → Other user-generated content (AI feature only)
- **Collected:** Yes · **Shared:** Yes (with the AI provider the user chose)
- **Processed ephemerally?** Yes
- **Required or optional?** **Optional** — only if the user adds their own API key
- **Purpose:** App functionality
- The specific text/image the user runs an AI action on, sent directly from the
  device to Gemini/Anthropic and billed to the user's own account.

### Everything else → NOT collected
Declare these as **not collected**, because they never leave the device:

- Location (on-device geofence only; no background location, no history)
- Contacts (participant names stay local)
- Photos / videos / audio recordings (captures stay local)
- Health & fitness (Health Connect read on-device)
- Files & docs, Messages, Calendar *as a device-read*, Contacts upload
- App activity/analytics, crash logs, device IDs, advertising ID

**No analytics SDK, no ads SDK, no tracking.**

---

## 3. Other App content sections

| Section | Answer |
|---|---|
| **Privacy policy URL** | your hosted `privacy.html` (see §5) |
| **Ads** | No ads |
| **In-app purchases** | None (this release — free) |
| **Content rating** | Complete questionnaire; no objectionable content → expect Everyone |
| **Target audience** | Adults (18+); not designed for children |
| **News app** | No |
| **COVID-19 / health apps** | No (Health Connect read is a fitness convenience, not a medical claim) |
| **Government app** | No |
| **Financial features** | None |
| **Data safety — account creation** | No account required |

---

## 4. Permissions justification (if asked)

| Permission | Why |
|---|---|
| `POST_NOTIFICATIONS` | Task reminders the user schedules |
| `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` | Reminders must fire at the exact minute a task is due |
| `RECEIVE_BOOT_COMPLETED` | Re-arm scheduled reminders after a reboot |
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | Optional arrival reminders for a place; **foreground only**, no background location declared |
| `READ_CONTACTS` | Optional — add participants to a task; stays on device |
| `RECORD_AUDIO` | Optional — voice notes and dictation |
| `INTERNET` | Google sync and the user's own AI provider |

---

## 5. Hosting the privacy policy

Play needs a **public URL**. `docs/privacy.html` is ready to host as-is.

**GitHub Pages (free, quickest):**
1. Push the repo to GitHub (a public repo, or a small public repo containing just `docs/`).
2. Repo **Settings → Pages** → Source: `main` branch, folder `/docs`.
3. Wait ~1 minute → URL is
   `https://<user>.github.io/<repo>/privacy.html`
4. Open it, confirm it renders, paste that URL into Play Console.

The same URL is also required for **Google OAuth verification** of the sensitive
scopes — use one URL in both places.

---

## 6. Before you upload — check these are still true

- [ ] `kDrivePickerEnabled == false` (keeps scopes to `tasks` + `calendar.events`)
- [ ] No `ACCESS_BACKGROUND_LOCATION` in the manifest
- [ ] Version bumped; each Play upload needs a **new, higher** version code
- [ ] `veera@realmaya.com` actually receives mail — Play and Google's OAuth
      verification both correspond through it, and a bounce stalls the review
- [ ] Legal entity name in `privacy.html` is correct (currently "Realmaya")
