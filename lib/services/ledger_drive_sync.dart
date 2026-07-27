import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_settings.dart';
import 'google/google_sync_service.dart';
import 'ledger_sync_service.dart';

/// §9 automatic device-to-device sync through Google Drive's hidden **app-data
/// folder** (`drive.appdata`). Saara stores only its own encrypted ledger file
/// there and cannot see the user's real Drive files. Unlike the folder route
/// this needs no locally-mirrored folder, so it's seamless on mobile too — the
/// cost is one extra (sensitive, not restricted) OAuth scope.
///
/// The passphrase (the shared key both devices decrypt with) lives in the OS
/// keystore, never in the database or in Drive.
class LedgerDriveSync {
  LedgerDriveSync({
    required this.settings,
    required this.sync,
    required this.google,
  });

  final AppSettings settings;
  final LedgerSyncService sync;
  final GoogleSyncService google;

  static const _passKey = 'drive_sync_passphrase';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<bool> get isEnabled async {
    if (!await settings.driveSyncEnabled()) return false;
    final pass = await _storage.read(key: _passKey);
    return pass != null && pass.isNotEmpty;
  }

  /// Turn Drive sync on: needs a live Google connection (the appdata scope is
  /// granted at connect). A first pass runs immediately.
  Future<FolderSyncResult> enable(String passphrase) async {
    if (!await google.isConnected()) {
      throw StateError(
        'Connect Google first (Settings → Google Tasks sync), then turn on '
        'Drive sync.',
      );
    }
    await _storage.write(key: _passKey, value: passphrase);
    await settings.setDriveSyncEnabled(true);
    return sync.syncDrive(google, passphrase);
  }

  Future<void> disable() async {
    await settings.setDriveSyncEnabled(false);
    await _storage.delete(key: _passKey);
  }

  /// One pass now. Null when off or not connected — the caller treats that as a
  /// quiet no-op.
  Future<FolderSyncResult?> syncNow() async {
    if (!await isEnabled) return null;
    if (!await google.isConnected()) return null;
    final pass = await _storage.read(key: _passKey);
    if (pass == null || pass.isEmpty) return null;
    return sync.syncDrive(google, pass);
  }
}
