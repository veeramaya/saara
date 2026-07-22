import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'services/geofence_service.dart';
import 'services/google/auto_sync.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local notifications + timezone data for the morning/evening rhythm (§8).
  // Guarded so a plugin/init failure on any device can never block launch.
  try {
    await NotificationService.instance.init();
  } catch (e, s) {
    debugPrint('Notification init failed (non-fatal): $e\n$s');
  }

  // WorkManager for background Google auto-sync (§8, §9). Mobile only; guarded.
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await Workmanager().initialize(syncCallbackDispatcher);
    } catch (e, s) {
      debugPrint('WorkManager init failed (non-fatal): $e\n$s');
    }
    // §8 geofencing engine for located-task arrival prompts.
    try {
      await SaaraGeofence.initialize();
    } catch (e, s) {
      debugPrint('Geofence init failed (non-fatal): $e\n$s');
    }
  }

  runApp(const ProviderScope(child: SaaraApp()));
}
