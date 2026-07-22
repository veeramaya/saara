import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../providers.dart';

/// §4 duplicate an event onto another date, **carrying its whole agenda**.
///
/// Built for a repeating session (e.g. a training) that keeps the same
/// run-of-show on a new date. Better than calendar recurrence here: recurrence
/// repeats the time block but not the action items underneath it.
///
/// Every action item's start is shifted by the **same offset** as the event, so
/// a 6:00–11:00 PM structure lands intact on the new day. Durations, notes,
/// links and area are copied; completion state is not — it's a fresh run.
Future<int> duplicateEventToDate(
  WidgetRef ref, {
  required Task event,
  required DateTime newStart,
}) async {
  final dao = ref.read(taskDaoProvider);
  final uuid = ref.read(uuidProvider);
  final now = DateTime.now();

  final oldStart = event.scheduledStart ?? event.dueDate ?? now;
  final shift = newStart.difference(oldStart);

  final newEventId = uuid.v4();
  await dao.insertTask(
    TasksCompanion.insert(
      id: newEventId,
      title: event.title,
      kind: const Value(TaskKind.event),
      areaId: Value(event.areaId),
      scheduledStart: Value(newStart),
      dueDate: Value(newStart),
      durationMin: Value(event.durationMin),
      notes: Value(event.notes),
      locationName: Value(event.locationName),
      meetingLink: Value(event.meetingLink),
      meetingProvider: Value(event.meetingProvider),
      documentLink: Value(event.documentLink),
      reminderOffsets: Value(event.reminderOffsets),
      status: const Value(TaskStatus.created),
      source: const Value(TaskSource.manual),
      createdAt: now,
      updatedAt: now,
    ),
  );

  // Clone the agenda, shifted by the same delta so the running order holds.
  final children = await dao.childTasksForEvent(event.id);
  var copied = 0;
  for (final c in children) {
    final childStart = c.scheduledStart?.add(shift);
    await dao.insertTask(
      TasksCompanion.insert(
        id: uuid.v4(),
        title: c.title,
        kind: const Value(TaskKind.task),
        parentEventId: Value(newEventId),
        areaId: Value(c.areaId),
        scheduledStart: Value(childStart),
        dueDate: Value(childStart),
        durationMin: Value(c.durationMin),
        notes: Value(c.notes), // speaker notes carry over
        documentLink: Value(c.documentLink),
        meetingLink: Value(c.meetingLink),
        status: const Value(TaskStatus.created), // fresh run, not completed
        source: const Value(TaskSource.manual),
        createdAt: now,
        updatedAt: now,
      ),
    );
    copied++;
  }

  ref.invalidate(allTasksProvider);

  ref.invalidate(unscheduledTasksProvider);
  ref.invalidate(childTaskCountsProvider);
  ref.invalidate(childTasksForEventProvider(newEventId));
  ref.invalidate(
    tasksForDayProvider(DateTime(newStart.year, newStart.month, newStart.day)),
  );
  return copied;
}
