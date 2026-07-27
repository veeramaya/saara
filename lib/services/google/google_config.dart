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

/// Scopes requested incrementally (§2). Tasks read/write; Calendar events for
/// the optional add-on. Device-to-device sync does **not** go through Google —
/// it travels as a ledger file the user moves between devices (WhatsApp, a
/// shared folder, Share-to-Saara). So Saara requests **no Drive scope at all**,
/// keeping this list *sensitive-only* and the review light.
const kGoogleScopes = <String>[
  'https://www.googleapis.com/auth/tasks',
  'https://www.googleapis.com/auth/calendar.events',
  if (kDrivePickerEnabled) 'https://www.googleapis.com/auth/drive.readonly',
];
