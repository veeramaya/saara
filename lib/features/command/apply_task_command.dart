import 'dart:async';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time_context.dart';
import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../providers.dart';
import '../../services/geofence_service.dart';
import '../../services/notification_service.dart';

/// §19 shared applier for an AI-interpreted task command — used by "Tell Saara"
/// and the Saara chat so both act identically. Performs the mutation, refreshes
/// providers, pushes to Google, and returns a short human confirmation.
///
/// [data] is the parsed command JSON. For edits, pass the matched [task]. For a
/// create, [areaId] is the user-confirmed area (keeps metrics accurate).
Future<({String message, String? taskId})> applyTaskCommand(
  WidgetRef ref,
  Map<String, dynamic> data, {
  Task? task,
  String? areaId,
}) async {
  final db = ref.read(appDatabaseProvider);
  final now = DateTime.now();
  final action = data['action'].toString();
  DateTime? affected;
  String result;
  // The task the user can then open to verify/modify — null for a delete.
  String? affectedId = task?.id;
  bool created = false;

  switch (action) {
    case 'create':
      final title = data['title']?.toString().trim() ?? '';
      if (title.isEmpty) throw 'No title for the new task.';
      final dt = parseAiDateTime(data['datetime']);
      // An event is a time-blocked calendar entry; without a time it's a to-do.
      final kind = (data['kind'] == 'event' && dt != null)
          ? TaskKind.event
          : TaskKind.task;
      final aid = areaId ?? _matchAreaId(ref, data['area']?.toString());
      final link = data['link']?.toString();
      String? meeting, doc;
      if (link != null && link.isNotEmpty) {
        if (data['linkType'] == 'meeting') {
          meeting = link;
        } else {
          doc = link;
        }
      }
      final dur = data['durationMinutes'];
      final notes = data['notes']?.toString().trim();
      final loc = data['location']?.toString().trim();
      final rrule = _rruleFor(data['repeat']);
      final id = ref.read(uuidProvider).v4();
      // Through create(): a task you asked Saara to add is a commitment, so it
      // is released, and it is recorded in the ledger like any other (§4).
      await ref
          .read(taskServiceProvider)
          .create(
            TasksCompanion.insert(
              id: id,
              title: title,
              kind: Value(kind),
              scheduledStart: Value(dt),
              dueDate: Value(dt),
              durationMin: Value(dur is num ? dur.toInt() : null),
              rrule: Value(rrule),
              areaId: Value(aid),
              locationName: Value(loc == null || loc.isEmpty ? null : loc),
              meetingLink: Value(meeting),
              documentLink: Value(doc),
              notes: Value(notes == null || notes.isEmpty ? null : notes),
              source: const Value(TaskSource.conversation),
              createdAt: now,
              updatedAt: now,
            ),
          );
      affected = dt;
      affectedId = id;
      created = true;
      result = rrule == null
          ? 'Created “$title”.'
          : 'Created “$title” (repeats).';
      break;

    case 'reschedule':
      final dt = parseAiDateTime(data['datetime']);
      if (dt == null || task == null) throw 'No valid date/task.';
      await (db.update(db.tasks)..where((t) => t.id.equals(task.id))).write(
        TasksCompanion(
          scheduledStart: Value(dt),
          dueDate: Value(dt),
          updatedAt: Value(now),
        ),
      );
      if (task.reminderOffsets != null && task.reminderOffsets!.isNotEmpty) {
        await NotificationService.instance.scheduleTaskReminder(
          taskId: task.id,
          title: task.title,
          when: dt,
          offsetsMinutes: task.reminderOffsets!,
        );
      }
      affected = dt;
      result = 'Moved “${task.title}”.';
      break;

    case 'rename':
      final title = data['title']?.toString().trim();
      if (title == null || title.isEmpty || task == null) {
        throw 'No new title/task.';
      }
      await (db.update(db.tasks)..where((t) => t.id.equals(task.id))).write(
        TasksCompanion(title: Value(title), updatedAt: Value(now)),
      );
      result = 'Renamed to “$title”.';
      break;

    case 'complete':
      if (task == null) throw 'No task to complete.';
      await ref.read(taskServiceProvider).complete(task);
      await NotificationService.instance.cancelTaskReminder(task.id);
      await SaaraGeofence.remove(task.id);
      result = 'Marked “${task.title}” complete.';
      break;

    case 'delete':
      if (task == null) throw 'No task to delete.';
      await (db.update(db.tasks)..where((t) => t.id.equals(task.id))).write(
        TasksCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
      await NotificationService.instance.cancelTaskReminder(task.id);
      await SaaraGeofence.remove(task.id);
      affectedId = null; // nothing to open — it's gone
      result = 'Deleted “${task.title}”.';
      break;

    default:
      throw 'Unknown action.';
  }

  // Refresh anything showing tasks, then push to Google.
  if (task != null) ref.invalidate(taskByIdProvider(task.id));
  ref.invalidate(allTasksProvider);
  ref.invalidate(unscheduledTasksProvider);
  ref.invalidate(scheduleConflictsProvider);
  // A newly-created repeating task is a template — materialise its occurrences
  // now so they show up straight away, not only on the next app open.
  if (created) ref.invalidate(materializeRecurringProvider);
  for (final d in {now, affected, task?.scheduledStart}) {
    if (d != null) {
      ref.invalidate(tasksForDayProvider(DateTime(d.year, d.month, d.day)));
      ref.invalidate(tasksBetweenProvider); // calendar views
    }
  }
  unawaited(() async {
    try {
      if (await ref.read(googleSyncServiceProvider).isConnected()) {
        await ref.read(googleSyncOrchestratorProvider).syncAll();
      }
    } catch (_) {}
  }());
  return (message: result, taskId: affectedId);
}

/// Maps the AI's plain repeat word to an RRULE. "once"/absent → no repeat.
String? _rruleFor(Object? repeat) => switch (repeat?.toString().toLowerCase()) {
  'daily' => 'FREQ=DAILY',
  'weekly' => 'FREQ=WEEKLY',
  'monthly' => 'FREQ=MONTHLY',
  _ => null,
};

String? _matchAreaId(WidgetRef ref, String? name) {
  if (name == null || name.trim().isEmpty) return null;
  final areas = ref.read(activeAreasProvider).valueOrNull ?? const [];
  final want = name.trim().toLowerCase();
  final m = areas.firstWhereOrNull(
    (a) =>
        a.displayName.toLowerCase().contains(want) ||
        a.baseCategory.name == want,
  );
  return m?.id;
}
