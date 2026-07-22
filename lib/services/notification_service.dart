import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// §8 Notification engine (local only — no push required for core function, §2).
///
/// Phase 1 wires the two daily agent notifications (morning brief, evening
/// review) as repeating local schedules. Per-task reminders (opt-in), escalation
/// rules, and the WorkManager nightly-rollover jobs build on top of this in
/// their phases (§8, §17). All content is precomputed on-device; nothing is
/// fetched from a server.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _dailyChannel = AndroidNotificationDetails(
    'saara_daily',
    'Daily agent',
    channelDescription: 'Morning brief and evening review (§7.3, §7.4)',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _taskChannel = AndroidNotificationDetails(
    'saara_task',
    'Task reminders',
    channelDescription:
        'Per-task reminders (§8) — opt-in, before a task starts',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const morningId = 1001;
  static const eveningId = 1002;

  /// flutter_local_notifications has no Windows/Linux implementation. On those
  /// desktop dev builds the service no-ops instead of throwing (macOS, Android,
  /// iOS are all supported).
  bool get _supported => !(Platform.isWindows || Platform.isLinux);

  Future<void> init() async {
    if (_ready) return;
    if (!_supported) {
      _ready = true;
      return;
    }
    tz.initializeTimeZones();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false, // just-in-time (§15), not at startup
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    _ready = true;
  }

  /// Ask for notification permission at first meaningful use (§15 just-in-time).
  Future<bool> requestPermission() async {
    if (!_supported) return true;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final iOS = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final a = await android?.requestNotificationsPermission() ?? true;
    final i =
        await iOS?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;
    return a && i;
  }

  /// §7.3 morning brief (default 07:00) and §7.4 evening review (default 21:00),
  /// adjustable in Settings. Repeats daily at the given wall-clock time.
  Future<void> scheduleDailyAgent({
    required int hour,
    required int minute,
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_supported) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOf(hour, minute),
      const NotificationDetails(android: _dailyChannel),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  /// Show a notification immediately (§8) — used by the geofence arrival
  /// callback. Safe to call from a background isolate (ensures init).
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_supported) return;
    await init();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: _taskChannel),
    );
  }

  /// §8 per-task reminder — schedule a heads-up notification at [when] plus each
  /// (negative) offset in [offsetsMinutes] (e.g. -15 = 15 min before). Replaces
  /// any prior reminders for this task. Requests notification permission if
  /// needed, and falls back to inexact scheduling if exact alarms aren't allowed.
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required DateTime when,
    required List<int> offsetsMinutes,
  }) async {
    if (!_supported) return;
    await requestPermission();
    await cancelTaskReminder(taskId);
    final now = tz.TZDateTime.now(tz.local);
    for (var i = 0; i < offsetsMinutes.length && i < 3; i++) {
      final fire = tz.TZDateTime.from(
        when.add(Duration(minutes: offsetsMinutes[i])),
        tz.local,
      );
      if (!fire.isAfter(now)) continue;
      const body = 'Coming up — tap to open.';
      final id = _taskNotifId(taskId, i);
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          fire,
          const NotificationDetails(android: _taskChannel),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        // Exact alarms may be disallowed (Android 14+) — fall back to inexact.
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          fire,
          const NotificationDetails(android: _taskChannel),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<void> cancelTaskReminder(String taskId) async {
    if (!_supported) return;
    for (var i = 0; i < 3; i++) {
      await _plugin.cancel(_taskNotifId(taskId, i));
    }
  }

  /// Deterministic 31-bit notification id from a task UUID + offset index, so a
  /// reminder can be cancelled/replaced later.
  int _taskNotifId(String taskId, int i) {
    var h = 5381;
    for (final c in taskId.codeUnits) {
      h = ((h << 5) + h + c) & 0x1fffffff;
    }
    return 200000 + (h % 100000000) + i;
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
