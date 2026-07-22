# Publishing Saara to Play Store Internal Testing (§18.3)

This gets the app onto the **Internal testing** track so you and up to 100
testers can install it from the Play Store like a normal app. No public listing,
no review wait for internal testing.

---

## 0. What's already done (in this repo)

- ✅ Release build compiles: `flutter build appbundle --release`
- ✅ **Upload signing** configured — `android/app/build.gradle.kts` reads
  `android/key.properties` and signs with `android/app/upload-keystore.jks`.
- ✅ App ID: `com.realmaya.saara`; app name "Saara".

### ⚠️ Back up your signing key — do this now

These two files are **gitignored on purpose** and exist only on this machine:

- `android/app/upload-keystore.jks` — your upload key
- `android/key.properties` — its passwords (currently `SaaraUpload2026#`)

Copy both somewhere safe (password manager / private backup). If you lose them
you can still recover: with **Play App Signing** (enabled by default when you
create the app), Google holds the real app-signing key and you can **reset the
upload key** from Play Console → Test and release → App integrity. Consider
changing the password to your own: re-run the `keytool` command in the README
and update `key.properties`.

---

## 1. Build the bundle to upload

```bash
flutter build appbundle --release
```
Artifact: `build/app/outputs/bundle/release/app-release.aab`.

Bump `version:` in `pubspec.yaml` (e.g. `1.0.0+1` → `1.0.0+2`) before every new
upload — Play rejects a re-used version code.

---

## 2. Create the app in Play Console

1. Go to <https://play.google.com/console> with the **Realmaya** developer
   account (needs the one-time US$25 registration if not already done).
2. **Create app** → name "Saara", default language, **App**, **Free**. Accept
   the declarations. Keep **Play App Signing** enabled (default).

---

## 3. Internal testing release

1. Left nav → **Test and release → Testing → Internal testing**.
2. **Testers** tab → create an email list → add your + testers' Google account
   emails. (These accounts can install the test build.)
3. **Releases** tab → **Create new release**.
4. Upload `app-release.aab`. Play will show it's signed by your upload key and
   re-signed with the Google-managed app-signing key.
5. Add a short **release note**, **Save → Review release → Start rollout to
   Internal testing**.
6. Copy the **opt-in URL** from the Testers tab, open it on each test device
   (signed in with a tester account), accept, then install via the Play link.

Internal testing builds go live in minutes (no full review).

---

## 4. Declarations Play requires before rollout

Even for internal testing, the **App content** section (left nav → Policy → App
content) must be completed. For Saara most are simple thanks to the zero-data
posture (§14, §15):

| Declaration | Saara's answer |
|---|---|
| **Privacy policy** | Required — host one at `realmaya.com/saara` stating on-device-only processing, zero data collection (§15). Paste the URL. |
| **Data safety** | **"No data collected."** Feedback is user-initiated via their own mail app, not app data collection (§14, §15). |
| **Ads** | No ads. |
| **Content rating** | Fill the questionnaire (productivity app → likely "Everyone"). |
| **Target audience** | Not directed at children. |
| **Government app / financial / health** | No. |
| **Data collection & COPPA** | None. |

You can start internal testing before the full **production** listing (store
graphics, screenshots) is done — those are only needed for public release.

---

## 5. Known gaps to address before a *public* launch (not blockers for internal test)

- ✅ **App icon** — done. Original Saara mark (broken ring + checkmark, deep
  teal) with Android adaptive icons + iOS sizes, generated from
  `tool/gen_icon.dart` → `flutter_launcher_icons`.
- ✅ **App label** — set to "Saara".
- Google OAuth / Calendar isn't in Phase 1, so **no sensitive-scope
  verification** is needed yet (that arrives with §9 in Phase 2).
- Deferred vs. PRD Phase 1: Todoist import (→ Excel/CSV), text share-target,
  WorkManager rollover — see the README deferred table.
