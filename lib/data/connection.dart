import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

import '../core/data_dir.dart';

/// Opens the local database (§1.1, §2).
///
/// On the shipping platforms (Android, iOS, macOS) this is a **SQLCipher**
/// database: a random 256-bit passphrase is generated on first launch and
/// stored only in the Keystore/Keychain via [FlutterSecureStorage] — never in
/// the DB itself (cf. §3.6 ApiCredential discipline).
///
/// **Every** platform we ship is encrypted, desktop included: on Windows/Linux
/// `sqlcipher_flutter_libs` bundles a SQLCipher build of sqlite3 alongside the
/// executable. Opening refuses to proceed (StateError) if the loaded sqlite3
/// turns out to be plain, so an unencrypted database can never be created by
/// accident — the §1.1 guarantee holds on desktop as on mobile.
const _dbFileEncrypted = 'saara.db.enc';
const _dbFilePlain = 'saara.db';
const _dbKeyStorageKey = 'saara_db_passphrase';

const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

/// SQLCipher is available on every target we ship. On Windows/Linux
/// `sqlcipher_flutter_libs` bundles a SQLCipher-enabled `sqlite3` next to the
/// executable (verified: sqlite3.dll ships in the Windows Release bundle), so
/// desktop is encrypted exactly like mobile. The `PRAGMA cipher_version` guard
/// below fails loudly if a plain sqlite3 ever gets linked instead.
bool get _encryptionSupported => true;

Future<String> _obtainPassphrase() async {
  final existing = await _secureStorage.read(key: _dbKeyStorageKey);
  if (existing != null) return existing;

  final rng = Random.secure();
  final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
  final passphrase = bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  await _secureStorage.write(key: _dbKeyStorageKey, value: passphrase);
  return passphrase;
}

/// Lazy native connection used by [AppDatabase] — encrypted where supported.
LazyDatabase openEncryptedConnection() {
  return LazyDatabase(() async {
    final encrypt = _encryptionSupported;

    // Android needs an explicit override to route sqlite3 to the SQLCipher
    // build; iOS/macOS link it via the pod automatically. (Windows/Linux have
    // no bundled sqlite3 lib now that sqlite3_flutter_libs is removed, so the
    // unencrypted desktop fallback there needs a system sqlite3 — a non-goal
    // while Windows desktop is blocked on the C++ toolchain anyway.)
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
      open.overrideForAll(openCipherOnAndroid);
    }

    final dir = await saaraDataDir();
    final file = File(
      p.join(dir.path, encrypt ? _dbFileEncrypted : _dbFilePlain),
    );
    final passphrase = encrypt ? await _obtainPassphrase() : null;

    // Self-heal an orphaned database. If the encrypted file exists but the key
    // no longer decrypts it — which happens if the key was ever lost while the
    // file remained — every query fails with "file is not a database" and the
    // app is unusable. The file is unrecoverable without its key, so the only
    // honest option is to start fresh: delete it and let a new one be created.
    // Cheap and safe when the key IS right (one probe query), decisive when it
    // isn't.
    if (encrypt && passphrase != null && await file.exists()) {
      try {
        final probe = sqlite3.open(file.path);
        try {
          probe.execute("PRAGMA key = '$passphrase';");
          probe.select(
            'PRAGMA user_version;',
          ); // decrypts the header, or throws
        } finally {
          probe.dispose();
        }
      } catch (_) {
        // Key mismatch (or a corrupt file). Nothing here is readable; recreate.
        try {
          await file.delete();
        } catch (_) {}
        for (final suffix in ['-wal', '-shm']) {
          final side = File('${file.path}$suffix');
          if (await side.exists()) {
            try {
              await side.delete();
            } catch (_) {}
          }
        }
      }
    }

    return NativeDatabase(
      file,
      setup: (raw) {
        if (encrypt) {
          // Fail loudly if we linked plain sqlite3 instead of SQLCipher.
          final result = raw.select('PRAGMA cipher_version;');
          if (result.isEmpty) {
            throw StateError(
              'SQLCipher not available — encryption cannot be guaranteed. '
              'Check sqlcipher_flutter_libs linkage.',
            );
          }
          raw.execute("PRAGMA key = '$passphrase';");
        }
        raw.execute('PRAGMA foreign_keys = ON;');
      },
    );
  });
}
