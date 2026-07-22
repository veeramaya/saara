# Google Tasks + Calendar sync — one-time setup (you do this)

Goal: **import your Google Tasks into Saara**, and **push Saara tasks back as
Google Tasks** (which then appear in Google Calendar's task layer). This needs a
Google Cloud project + OAuth — I'll wire the app once the client exists.

> Google **Tasks** and Google **Calendar** are separate products. Tasks you
> create via the Tasks API show up in the Calendar app's "Tasks" view — which is
> exactly what you asked for. Calendar *events* are a separate optional add-on.

## Your app identity (needed below)

- **Package name:** `com.realmaya.saara`
- **SHA-1 (debug, for `flutter run`):**
  `94:46:13:D9:5B:5D:E4:6E:B6:E6:6F:CE:6E:34:04:A5:B8:CD:C7:24`
- **SHA-1 (upload key):**
  `E1:17:0C:B4:B3:E9:8F:68:E8:B4:0A:D0:9E:49:09:94:08:A6:A5:EA`
- **SHA-1 (Play App Signing) — get this from Play Console** →
  Test and release → App integrity → App signing → copy the SHA-1. **This is the
  one that matters for the app installed from Play.**

## Click-by-click (console.cloud.google.com)

> A Google Cloud project here is just the app's **OAuth registration** — no
> backend, no data storage. Tasks/Calendar traffic stays device→Google direct
> (§1.1). It's free and required by Google for any app that calls their APIs.

### 1. Create the project
1. Open **console.cloud.google.com** → sign in with your Gmail.
2. Top bar, click the **project dropdown** (left of the search box) → **New
   project**.
3. Name: **Saara** → **Create**. Wait a few seconds, then make sure **Saara** is
   selected in the dropdown.

### 2. Enable the two APIs
1. Left menu (☰) → **APIs & Services → Library**.
2. Search **"Google Tasks API"** → open it → **Enable**.
3. Back to Library, search **"Google Calendar API"** → **Enable**.

### 3. Configure the consent screen (one-time)
Left menu → **APIs & Services → OAuth consent screen** *(newer console: **Google
Auth Platform → Branding / Audience**).* Click **Get started** and fill:
- **App name:** Saara · **User support email:** your Gmail.
- **Audience:** **External** → Next.
- **Contact email:** your Gmail → agree → **Create**.
Then open the **Audience** tab → **Test users** → **Add users** → add
`rvr2300@gmail.com` (only test users can sign in while unverified — that's fine).

### 4. Create the OAuth clients
Left menu → **APIs & Services → Credentials** *(or **Google Auth Platform →
Clients**)* → **+ Create credentials → OAuth client ID**.

**a) Android client** (makes sign-in work on the phone)
- Application type: **Android**
- Name: `Saara Android (Play)`
- Package name: `com.realmaya.saara`
- SHA-1: your **Play App Signing** SHA-1 → Play Console → **Test and release →
  App integrity → App signing → App signing key certificate → SHA-1** → copy.
- **Create.**
- **Repeat** to make a second Android client `Saara Android (debug)` with SHA-1
  `94:46:13:D9:5B:5D:E4:6E:B6:E6:6F:CE:6E:34:04:A5:B8:CD:C7:24` (so `flutter run`
  works too). *(Optional: a third with the upload SHA-1 `E1:17:0C:B4:B3:E9:8F:68:E8:B4:0A:D0:9E:49:09:94:08:A6:A5:EA`.)*

**b) Web client** (the value I need in the app code)
- **+ Create credentials → OAuth client ID** again.
- Application type: **Web application**
- Name: `Saara Web`
- Leave redirect URIs empty → **Create.**
- A dialog shows **Your Client ID** like `1234-abc.apps.googleusercontent.com` —
  **copy it.** (Find it again anytime: Credentials → click the Web client.)

### 5. Send me the Web client ID
Paste the `…apps.googleusercontent.com` **Web** client ID here. That's the only
value I need — then I wire the two-way Google Tasks/Calendar sync.

## Then I build

- `google_sign_in` (incremental scope request, §2) → user taps "Connect Google".
- **Import:** read your Google Task lists + tasks → create Saara tasks
  (idempotent by Google task id).
- **Push:** Saara tasks → Google Tasks (so they show in Calendar's task view),
  keeping the link for updates/completion sync.
- Conflict rule: last-writer-wins (§9).

Everything stays **device → Google direct** (no Realmaya server, §1.1).
