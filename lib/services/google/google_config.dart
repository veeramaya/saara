// Google OAuth config (§9). Sign-in matches the **Android** OAuth client by
// package (`com.realmaya.saara`) + the running build's SHA-1 — that client is
// what must exist in the Cloud project. No serverClientId is used: we only
// need an access token for the Tasks/Calendar REST APIs, which the Android
// client provides directly. No secret here.

/// §11 Drive file picker. `drive.readonly` is a **restricted** scope: shipping
/// it publicly forces Google's CASA third-party security assessment (weeks +
/// cost). `tasks` and `calendar.events` are only *sensitive*, which needs the
/// lighter brand review. So the picker is **off for the free launch** — users
/// paste a Drive link instead, which needs no scope at all. Flip this back on
/// (and re-add the scope below) once verification is done.
const bool kDrivePickerEnabled = false;

/// §9 Device-to-device sync through Google Drive's **app data folder** — a
/// hidden folder only Saara can see (`drive.appdata`). Saara stores just its
/// own encrypted ledger file there; it **cannot see any of the user's real Drive
/// files**. Unlike `drive`/`drive.readonly` this scope is only *sensitive*, not
/// restricted — so it needs the light brand review, never a CASA assessment.
const bool kDriveSyncEnabled = true;

/// Scopes requested incrementally (§2). Tasks read/write; Calendar events for
/// the optional add-on; drive.appdata for the hidden sync file. Keep this list
/// *sensitive-only* — restricted scopes (full Drive) are deliberately excluded.
const kGoogleScopes = <String>[
  'https://www.googleapis.com/auth/tasks',
  'https://www.googleapis.com/auth/calendar.events',
  if (kDrivePickerEnabled) 'https://www.googleapis.com/auth/drive.readonly',
  if (kDriveSyncEnabled) 'https://www.googleapis.com/auth/drive.appdata',
];
