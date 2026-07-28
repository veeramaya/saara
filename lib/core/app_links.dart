/// Outward links shown in-app. Kept in one place so they can be updated in a
/// single edit — and so the *app* points at a stable page we control, not
/// directly at a file host, letting us move the download without a new release.
library;

/// Where mobile users are sent to get the **Windows desktop** build. Point this
/// at the site's download page once it's live; until then it goes to the repo's
/// GitHub Releases, which always serves the latest published desktop build.
///
/// The site page (idea 2) is the brand-controlled front door — it carries the
/// install steps and the "unsigned → More info → Run anyway" note — and its own
/// Download button pulls the actual `.zip` / installer from GitHub Releases.
const String kDesktopDownloadUrl =
    'https://github.com/veeramaya/saara/releases/latest';
