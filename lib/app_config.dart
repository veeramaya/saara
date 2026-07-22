// Build-time feature flags (§17).

/// Background arrival geofencing declares ACCESS_BACKGROUND_LOCATION, which
/// triggers Google Play's strict background-location review (a declaration form
/// + a demo video). It's OFF for the first production release so the app can
/// ship without that gate; flip it on — and re-add the permission in the
/// manifest — once the review materials are prepared.
const bool kGeofenceEnabled = false;
