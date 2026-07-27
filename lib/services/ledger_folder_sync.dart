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
  ///
  /// The folder is **checked for writability first** — on Android a folder
  /// picked from a cloud provider (Google Drive, etc.) resolves to a read-only
  /// path, and saving it would then fail on every app open. Refuse up front with
  /// a clear message instead of persisting a folder that can never work.
  Future<FolderSyncResult> enable(String folderPath, String passphrase) async {
    final dir = Directory(folderPath);
    await _assertWritable(dir);
    await settings.setLedgerFolder(folderPath);
    await _storage.write(key: _passKey, value: passphrase);
    return sync.syncWatchedFolder(dir, passphrase);
  }

  Future<void> _assertWritable(Directory dir) async {
    try {
      if (!await dir.exists()) await dir.create(recursive: true);
      final probe = File(
        '${dir.path}${Platform.pathSeparator}.saara-write-test',
      );
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
    } catch (_) {
      throw const LedgerFolderException(
        "Saara can't write to that folder on this device. Automatic sync needs "
        'a normal local folder — cloud folders like Google Drive are read-only '
        'to apps here. On a phone use Export / Import instead; on desktop pick a '
        'folder such as your OneDrive or Google Drive Desktop folder.',
      );
    }
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
    try {
      return await sync.syncWatchedFolder(Directory(folder), pass);
    } on FileSystemException {
      // A configured folder that turned read-only (typically a cloud folder on
      // Android) — surface it plainly rather than a raw OS error.
      throw const LedgerFolderException(
        "Saara can't read/write the sync folder on this device. It looks like a "
        'cloud folder, which is read-only to apps here. Turn off automatic sync '
        'and use Export / Import, or point it at a normal local folder.',
      );
    }
  }
}

/// A folder-sync problem stated in plain language (its message is what the UI
/// shows), so a read-only cloud folder doesn't surface as a raw OS error.
class LedgerFolderException implements Exception {
  const LedgerFolderException(this.message);
  final String message;
  @override
  String toString() => message;
}
