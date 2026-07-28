/// §2 platform capability flags. Saara runs one codebase across mobile and
/// desktop, but several features are backed by mobile-only plugins (Health
/// Connect, contacts, geofencing, local notifications, camera). Gate on these
/// so the desktop build **hides** those surfaces instead of throwing
/// `MissingPluginException` at runtime.
///
/// Uses `defaultTargetPlatform` rather than `dart:io` so this file stays safe
/// to compile for web too.
library;

import 'package:flutter/foundation.dart';

bool get isWeb => kIsWeb;

bool get isMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

bool get isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux);

// ── Feature capabilities ────────────────────────────────────────────────────
// Each maps to a plugin that has no desktop implementation (verified against
// windows/flutter/generated_plugins.cmake).

/// On-device contacts for task participants (§11).
bool get supportsContacts => isMobile;

/// Local notifications / exact-alarm reminders (§8).
bool get supportsNotifications => isMobile;

/// OS geofences for arrival prompts (§8).
bool get supportsGeofence => isMobile;

/// **Live camera** capture. Mobile only — desktop has no camera source.
bool get supportsCamera => isMobile;

/// Choosing an existing image/video **file from disk**. Works on desktop too:
/// `image_picker_windows` wraps file_selector, so the gallery source opens a
/// normal file dialog. This is what makes screenshot → task work on desktop.
bool get supportsFilePick => isMobile || isDesktop;

/// **Recording** video — camera-bound, so mobile only.
bool get supportsVideo => isMobile;

/// In-app video *playback*: `video_player` has no Windows implementation, so
/// desktop hands a captured clip to the OS default player instead.
bool get supportsVideoPlayback => isMobile;

/// google_sign_in has no desktop implementation — desktop uses a loopback
/// OAuth flow instead (§9). Until that lands, Google sync is mobile-only.
bool get supportsGoogleSignIn => isMobile;

/// Background periodic sync (WorkManager) — mobile only; desktop syncs while
/// the app is open.
bool get supportsBackgroundSync => isMobile;

/// Audio capture + playback and speech-to-text DO work on Windows/macOS/Linux
/// (record_windows / audioplayers_windows / speech_to_text_windows), so there
/// is deliberately no flag for them.
