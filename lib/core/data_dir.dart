import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Where Saara keeps its encrypted database and capture media.
///
/// **Mobile** keeps the historical *Documents* location — changing it would
/// orphan an existing database (and its SQLCipher key), so it must not move.
///
/// **Desktop** deliberately uses the *application-support* directory
/// (`%APPDATA%` on Windows) instead. On Windows, `Documents` is very often
/// redirected into OneDrive; letting a live SQLite file sync from there risks
/// **corruption** (the `-wal`/`-shm` sidecars and half-written pages get
/// uploaded or reverted), and the synced copy is useless anyway because the
/// encryption key is device-local. Capture media would also be pushed to the
/// user's cloud, which local-first (§1.1) should never do implicitly.
Future<Directory> saaraDataDir() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    final dir = await getApplicationSupportDirectory();
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
  return getApplicationDocumentsDirectory();
}
