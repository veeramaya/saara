import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_settings.dart';
import 'ledger_sync_service.dart';

/// §9 Phase 3 — the automatic side of ledger sync: a folder Saara reads and
/// writes on its own, so the user doesn't export/import by hand each time.
///
/// The folder path lives in settings (not a secret); the passphrase lives in
/// the OS keystore (Keystore / DPAPI), never in the database. Point the folder
/// at OneDrive, Dropbox, or a synced drive and propagation is automatic — but
/// Saara only ever touches the filesystem, never a cloud API (§1.4).
class LedgerFolderSync {
  LedgerFolderSync({required this.settings, required this.sync});

  final AppSettings settings;
  final LedgerSyncService sync;

  static const _passKey = 'ledger_sync_passphrase';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<bool> get isConfigured async {
    final folder = await settings.ledgerFolder();
    final pass = await _storage.read(key: _passKey);
    return folder != null &&
        folder.isNotEmpty &&
        pass != null &&
        pass.isNotEmpty;
  }

  Future<String?> folderPath() => settings.ledgerFolder();

  /// Turn folder sync on: remember the folder and stash the passphrase. A first
  /// pass runs immediately so the other device sees this one straight away.
  Future<FolderSyncResult> enable(String folderPath, String passphrase) async {
    await settings.setLedgerFolder(folderPath);
    await _storage.write(key: _passKey, value: passphrase);
    return sync.syncWatchedFolder(Directory(folderPath), passphrase);
  }

  /// Stop syncing. Forgets the folder and wipes the stored passphrase; the files
  /// already written are left where they are.
  Future<void> disable() async {
    await settings.setLedgerFolder(null);
    await _storage.delete(key: _passKey);
  }

  /// Run one pass now. Null if not configured — the caller treats that as a
  /// quiet no-op, not an error (nothing is wrong with sync being off).
  Future<FolderSyncResult?> syncNow() async {
    final folder = await settings.ledgerFolder();
    final pass = await _storage.read(key: _passKey);
    if (folder == null || folder.isEmpty || pass == null || pass.isEmpty) {
      return null;
    }
    return sync.syncWatchedFolder(Directory(folder), pass);
  }
}
