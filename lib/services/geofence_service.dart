import 'package:flutter/widgets.dart';
import 'package:native_geofence/native_geofence.dart';

import '../app_config.dart';
import '../data/database.dart';
import 'notification_service.dart';

/// §8 arrival geofences for located tasks. Uses the OS geofencing service (low
/// power, fires even when the app is closed). On arrival, a notification invites
/// the user to do the task — "you're here, a good time to keep this."
const _radiusMeters = 150.0;

/// Background entry point — runs in its own isolate when a geofence triggers.
@pragma('vm:entry-point')
Future<void> saaraGeofenceCallback(GeofenceCallbackParams params) async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  try {
    await NotificationService.instance.init();
    for (final g in params.geofences) {
      final task = await db.taskDao.findById(g.id);
      final title = task?.title ?? 'A task';
      await NotificationService.instance.showNow(
        id: 300000 + (g.id.hashCode & 0x0fffffff),
        title: "You're near: $title",
        body: 'A good moment to keep this — tap to open.',
      );
    }
  } catch (_) {
    // never crash the callback
  } finally {
    await db.close();
  }
}

class SaaraGeofence {
  static Future<void> initialize() async {
    if (!kGeofenceEnabled) return;
    try {
      await NativeGeofenceManager.instance.initialize();
    } catch (_) {}
  }

  static Future<void> register(String taskId, double lat, double lng) async {
    if (!kGeofenceEnabled) return;
    await NativeGeofenceManager.instance.createGeofence(
      Geofence(
        id: taskId,
        location: Location(latitude: lat, longitude: lng),
        radiusMeters: _radiusMeters,
        triggers: const {GeofenceEvent.enter},
        iosSettings: IosGeofenceSettings(initialTrigger: false),
        androidSettings: const AndroidGeofenceSettings(
          initialTriggers: {GeofenceEvent.enter},
        ),
      ),
      saaraGeofenceCallback,
    );
  }

  static Future<void> remove(String taskId) async {
    if (!kGeofenceEnabled) return;
    try {
      await NativeGeofenceManager.instance.removeGeofenceById(taskId);
    } catch (_) {}
  }
}
