import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/database.dart';
import '../app_settings.dart';
import 'google_sync_orchestrator.dart';
import 'google_sync_service.dart';

const _taskName = 'googleSync';
const _uniqueName = 'saara-google-autosync';

/// WorkManager entry point — a top-level function invoked in a background
/// isolate when the periodic task fires (§8). Must be annotated so the AOT
/// compiler keeps it.
@pragma('vm:entry-point')
void syncCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) => runBackgroundSync());
}

/// The actual background reconcile. Opens its own DB + Google client (a fresh
/// isolate has none), syncs if enabled and connected, and always returns true
/// so WorkManager doesn't retry-storm on transient failures.
Future<bool> runBackgroundSync() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  final google = GoogleSyncService();
  try {
    final settings = AppSettings(db);
    if (!await settings.autoSyncEnabled()) return true;
    if (!await google.isConnected()) return true;
    final orchestrator = GoogleSyncOrchestrator(
      db: db,
      google: google,
      idGenerator: const Uuid().v4,
    );
    await orchestrator.syncAll();
    await settings.setLastSync(DateTime.now());
    return true;
  } catch (_) {
    return true; // swallow — try again next interval
  } finally {
    google.close();
    await db.close();
  }
}

/// Registers a periodic background sync (~30 min; Android enforces a 15-min
/// floor). Only runs on a connected network. Idempotent by unique name.
Future<void> enableBackgroundSync() {
  return Workmanager().registerPeriodicTask(
    _uniqueName,
    _taskName,
    frequency: const Duration(minutes: 30),
    constraints: Constraints(networkType: NetworkType.connected),
  );
}

Future<void> disableBackgroundSync() =>
    Workmanager().cancelByUniqueName(_uniqueName);
