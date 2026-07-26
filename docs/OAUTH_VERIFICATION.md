# Google OAuth verification pack (Saara)

To move the OAuth consent screen from **Testing → Published** and pass Google's
review. Saara requests **sensitive-only** scopes (no restricted/Drive), so this
is the light path: brand review + a short demo video. No CASA assessment.

## Consent screen — fields to fill (Google Cloud Console → OAuth consent screen)

| Field | Value |
|---|---|
| App name | **Saara** |
| User support email | veera@realmaya.com |
| App logo | (upload the 512×512 Saara icon — optional but speeds brand review) |
| Application home page | https://realmaya.com |
| Privacy policy URL | https://realmaya.com/… (your live privacy page) |
| Authorized domain | **realmaya.com** |
| Developer contact email | veera@realmaya.com |
| User type | **External**, then **Publish app** |

## Requested scopes (both **Sensitive**)

| Scope | Why Saara needs it (paste into the justification box) |
|---|---|
| `https://www.googleapis.com/auth/tasks` | Two-way sync of the user's own Google Tasks: Saara imports their tasks to show and act on in-app, and writes changes back (create / complete / reschedule / delete) so their to-dos stay consistent between Saara and Google Tasks. Sent device→Google directly; Realmaya operates no server and stores nothing. |
| `https://www.googleapis.com/auth/calendar.events` | Two-way sync of the user's own Calendar **events** for time-blocked tasks and meetings: Saara creates/updates events, attaches Google Meet links the user asks for, and reflects reschedules/deletions. Only event data is accessed — no other calendar or account data. Device→Google directly, no server. |

> Do **not** add `drive.readonly` or any Drive scope — the Drive picker is
> permanently off (`kDrivePickerEnabled = false`); users paste plain links.

## Demo video shot-list (~1–2 min, one continuous take, no cuts that hide consent)

Record on a real device/emulator; narrate briefly. Show, in order:

1. **App identity** — open Saara; show the app name/icon on the home screen.
2. **Start connect** — Settings → Google Tasks sync → **Connect**.
3. **Consent screen** — the Google account chooser, then the consent screen
   **clearly listing the Tasks and Calendar permissions**. Approve.
4. **Scopes in use — read** — tap **Sync now**; show Google Tasks / Calendar
   events importing into Saara.
5. **Scopes in use — write** — create a task/event in Saara, Sync, then show it
   **appearing in Google Tasks / Google Calendar** (switch to the Google app or
   web to prove the round-trip).
6. **Privacy** — show or state the privacy policy URL (realmaya.com).

Keep the OAuth consent screen fully visible for a few seconds — reviewers must
see the exact scopes being granted. Upload the video (unlisted YouTube is fine)
and paste the link in the verification request.

## Notes

- The **Play App Signing SHA‑1** (Play Console → Release → Setup → App signing)
  must be on the **production Android OAuth client** in Cloud Console, or Google
  sign-in fails for Play installs. (Desktop uses a separate *Desktop* client +
  loopback/PKCE — not part of this submission.)
- Verification typically takes several days to a few weeks — **start it now**, in
  parallel with the closed test and store paperwork.
