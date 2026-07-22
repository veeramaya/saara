# Saara — Windows desktop build

Same codebase as mobile, same **SQLCipher-encrypted** database. Nothing here
introduces a server: sync still goes device → your own Google account (§1.4).

---

## 1. One-time toolchain setup

| Requirement | How |
|---|---|
| **VS Build Tools 2022** + *Desktop development with C++* | `winget install --id Microsoft.VisualStudio.2022.BuildTools --override "--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"` (run **elevated**) |
| **C++ ATL** (needed by `flutter_secure_storage_windows`) | Visual Studio Installer → Build Tools → **Modify** → *Individual components* → tick **C++ ATL for latest v143 build tools (x86 & x64)** |
| **OpenSSL (dev)** — SQLCipher's crypto backend | `winget install --id ShiningLight.OpenSSL.Dev` → installs to `C:\Program Files\OpenSSL-Win64` |
| **Developer Mode** (Flutter plugin symlinks) | `start ms-settings:developers` → Developer Mode **On** |

Verify with `flutter doctor` — the *Visual Studio* line must be green.

> **Elevation gotcha:** `vs_installer.exe` with `--quiet` exits with code **5007**
> unless the shell is *actually* elevated (being an admin account isn't enough).
> Drop `--quiet` and the installer self-elevates via UAC.

---

## 2. Build

```powershell
$env:OPENSSL_ROOT_DIR = "C:/Program Files/OpenSSL-Win64"
flutter build windows --release
```

Output: `build\windows\x64\runner\Release\saara.exe` (~40 MB bundle, self-contained).

> **Stale-cache gotcha:** if a configure fails *before* the install-prefix block
> runs, CMake caches `CMAKE_INSTALL_PREFIX=C:/Program Files/saara` and every later
> build dies with `file cannot create directory … Maybe need administrative
> privileges`. Fix: `rm -rf build/windows` and rebuild.

---

## 3. What runs on desktop

**Works:** encrypted DB (SQLCipher + OpenSSL), secure key storage (DPAPI), tasks,
events, areas, timed agenda + run mode, progress/reliability, search, import /
export, Saara AI (BYOK over HTTPS), **audio notes**, **speech-to-text**.

**Gated off** via `lib/core/platform.dart` (no desktop plugin implementation):
Health Connect, contacts, geofencing, local notifications, camera/photo capture,
video playback, background sync.

---

## 4. Google sync on desktop

`google_sign_in` has no desktop implementation, so desktop uses Google's
**installed-app flow**: loopback redirect to `127.0.0.1` + **PKCE (S256)**, in
`lib/services/google/desktop_google_auth.dart`. Tokens live in the OS keychain.

**Setup:** Google Cloud Console → *Credentials* → **Create OAuth client ID** →
application type **Desktop app** → copy the client ID → paste it in Saara desktop
under **Settings → Google Tasks sync** → **Connect Google (opens browser)**.

No SHA-1 and no client secret are required for this client type.

Desktop and mobile then converge through **your** Google Tasks / Calendar:
tasks + events sync both ways. Areas, the integrity ledger, scores and captures
remain per-device (Google has nowhere to store them) — a later phase can sync an
**encrypted** blob via your own Drive app-folder.

---

## 5. Other desktop targets

`macos/` and `linux/` scaffolding already exists and `sqlcipher_flutter_libs`
supports both — same code, just build on that OS (`flutter build macos` /
`flutter build linux`).
