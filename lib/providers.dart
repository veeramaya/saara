import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'data/daos/area_dao.dart';
import 'data/daos/task_dao.dart';
import 'data/database.dart';
import 'domain/enums.dart';
import 'domain/measurable_progress.dart';
import 'domain/parser/deterministic_parser.dart';
import 'domain/report.dart';
import 'domain/schedule_conflicts.dart';
import 'domain/task_service.dart';
import 'domain/task_state_machine.dart';
import 'services/ai/ai_config.dart';
import 'services/app_settings.dart';
import 'services/export_service.dart';
import 'services/reset_service.dart';
import 'services/storage_service.dart';
import 'services/contacts_service.dart';
import 'services/health_service.dart';
import 'services/google/google_sync_orchestrator.dart';
import 'services/google/google_sync_service.dart';
import 'services/recurring_engine.dart';

/// App-wide dependency wiring (Riverpod, §2). Manual providers (no codegen) so
/// the graph is usable immediately after `flutter pub get`, before running the
/// Drift `build_runner` step.

/// The single encrypted database instance (§1.1, §3).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final uuidProvider = Provider<Uuid>((ref) => const Uuid());

/// §1.1 "Export all my data" — bundles every table + capture media into a zip.
final exportServiceProvider = Provider<ExportService>(
  (ref) => ExportService(ref.watch(appDatabaseProvider)),
);

/// §1.1 "Reset local data" — wipes everything held on this device.
final resetServiceProvider = Provider<ResetService>(
  (ref) => ResetService(ref.watch(appDatabaseProvider)),
);

/// §7.6 on-device media accounting + cleanup.
final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(ref.watch(appDatabaseProvider)),
);

final taskDaoProvider = Provider<TaskDao>(
  (ref) => ref.watch(appDatabaseProvider).taskDao,
);

final areaDaoProvider = Provider<AreaDao>(
  (ref) => ref.watch(appDatabaseProvider).areaDao,
);

final parserProvider = Provider<DeterministicParser>(
  (ref) => DeterministicParser(),
);

/// Tier 3 AI (§6): BYO-key config store, client, and current config.
final aiConfigStoreProvider = Provider<AiConfigStore>((ref) => AiConfigStore());

final llmServiceProvider = Provider<LlmService>((ref) {
  final service = LlmService();
  ref.onDispose(service.close);
  return service;
});

final aiConfigProvider = FutureProvider<AiConfig>((ref) {
  return ref.watch(aiConfigStoreProvider).load();
});

final taskStateMachineProvider = Provider<TaskStateMachine>((ref) {
  final uuid = ref.watch(uuidProvider);
  return TaskStateMachine(idGenerator: uuid.v4);
});

/// Facade that runs a state transition and persists it atomically (§3.3, §4).
final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService(
    dao: ref.watch(taskDaoProvider),
    machine: ref.watch(taskStateMachineProvider),
  );
});

/// Tasks for the given day (defaults to today) — backs the Home timeline (§7.1)
/// and the morning/evening flows (§7.3, §7.4).
final tasksForDayProvider = FutureProvider.family<List<Task>, DateTime>((
  ref,
  day,
) {
  return ref.watch(taskDaoProvider).tasksForDay(day);
});

/// Tasks within a date range (calendar view). The record key gives value
/// equality, so identical ranges share a cached result.
typedef DateRange = (DateTime from, DateTime to);
final tasksBetweenProvider = FutureProvider.family<List<Task>, DateRange>((
  ref,
  range,
) {
  return ref.watch(taskDaoProvider).tasksBetween(range.$1, range.$2);
});

/// Open items carried from before [day] that still need a disposition (§7.3).
final openItemsBeforeProvider = FutureProvider.family<List<Task>, DateTime>((
  ref,
  day,
) {
  return ref.watch(taskDaoProvider).openItemsBefore(day);
});

/// Active areas for the Areas grid / home rings (§7.5).
final activeAreasProvider = StreamProvider<List<Area>>((ref) {
  return ref.watch(areaDaoProvider).watchActiveAreas();
});

final areaByIdProvider = FutureProvider.family<Area?, String>((ref, id) {
  return ref.watch(areaDaoProvider).areaById(id);
});

/// A measurable result paired with its computed current-period progress.
typedef ResultWithProgress = (
  MeasurableResult result,
  MeasurableProgress progress,
);

/// Active measurable results for an area, each with progress (§7.5, §10).
final areaResultsProvider =
    FutureProvider.family<List<ResultWithProgress>, String>((
      ref,
      areaId,
    ) async {
      final dao = ref.watch(areaDaoProvider);
      final results = await dao.resultsForArea(areaId);
      final now = DateTime.now();
      final out = <ResultWithProgress>[];
      for (final r in results) {
        final period = currentPeriodKeys(r.cadence, now);
        final logs = await dao.logsForResultInRange(
          r.id,
          period.from,
          period.to,
        );
        out.add((r, computeProgress(r, logs)));
      }
      return out;
    });

/// Per-area integrity score for the wheel: average of measurable-result
/// progress, or (if no results) the area's task completion ratio.
class AreaScore {
  AreaScore({required this.area, required this.score, required this.hasData});
  final Area area;
  final double score; // 0..1
  final bool hasData;
}

final areaScoresProvider = FutureProvider<List<AreaScore>>((ref) async {
  final areaDao = ref.watch(areaDaoProvider);
  final taskDao = ref.watch(taskDaoProvider);
  final areas = await areaDao.activeAreas();
  final now = DateTime.now();
  const disposed = {
    TaskStatus.completed,
    TaskStatus.missed,
    TaskStatus.rejected,
  };

  final scores = <AreaScore>[];
  for (final a in areas) {
    final results = await areaDao.resultsForArea(a.id);
    if (results.isNotEmpty) {
      var sum = 0.0;
      for (final r in results) {
        final p = currentPeriodKeys(r.cadence, now);
        final logs = await areaDao.logsForResultInRange(r.id, p.from, p.to);
        sum += computeProgress(r, logs).fraction;
      }
      scores.add(
        AreaScore(area: a, score: sum / results.length, hasData: true),
      );
    } else {
      final tasks = await taskDao.tasksForArea(a.id);
      final done = tasks.where((t) => disposed.contains(t.status)).toList();
      final completed = done
          .where((t) => t.status == TaskStatus.completed)
          .length;
      scores.add(
        AreaScore(
          area: a,
          score: done.isEmpty ? 0 : completed / done.length,
          hasData: done.isNotEmpty,
        ),
      );
    }
  }
  return scores;
});

/// Tasks assigned to an area (§7.5 area task list).
final tasksForAreaProvider = FutureProvider.family<List<Task>, String>((
  ref,
  areaId,
) {
  return ref.watch(taskDaoProvider).tasksForArea(areaId);
});

/// A single task (backs the task-detail / lifecycle screen).
final taskByIdProvider = FutureProvider.family<Task?, String>((ref, id) {
  return ref.watch(taskDaoProvider).findById(id);
});

/// Action items grouped under an event (§4). Backs the event's "Action items"
/// list on the task-detail screen.
final childTasksForEventProvider = FutureProvider.family<List<Task>, String>((
  ref,
  eventId,
) {
  return ref.watch(taskDaoProvider).childTasksForEvent(eventId);
});

/// Count of action items per event (§4) — parentEventId → count. Powers the
/// "N action items" badge on event tiles in the Today and Tasks lists.
final childTaskCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final rows =
      await (db.select(db.tasks)
            ..where((t) => t.parentEventId.isNotNull())
            ..where((t) => t.deletedAt.isNull()))
          .get();
  final counts = <String, int>{};
  for (final t in rows) {
    final p = t.parentEventId;
    if (p != null) counts[p] = (counts[p] ?? 0) + 1;
  }
  return counts;
});

/// Every task/event (all statuses) — backs the global Tasks list + search (§7).
final allTasksProvider = FutureProvider<List<Task>>(
  (ref) => ref.watch(taskDaoProvider).allTasks(),
);

/// Open tasks carrying no date — surfaced under Today so a task saved with
/// "No date/time" doesn't disappear from every view (§7.1).
final unscheduledTasksProvider = FutureProvider<List<Task>>(
  (ref) => ref.watch(taskDaoProvider).unscheduledTasks(),
);

/// Soft-deleted tasks — the Trash view (§7).
final deletedTasksProvider = FutureProvider<List<Task>>(
  (ref) => ref.watch(taskDaoProvider).deletedTasks(),
);

/// Set of task ids that have at least one capture (§7.6) — powers the
/// "has:capture" search token and the capture indicator in the task list.
final taskIdsWithCapturesProvider = FutureProvider<Set<String>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final rows =
      await (db.selectOnly(db.captures, distinct: true)
            ..addColumns([db.captures.attachedId])
            ..where(db.captures.attachedType.equalsValue(AttachedType.task)))
          .get();
  return {for (final r in rows) r.read(db.captures.attachedId)!};
});

/// Captures (text/photo/audio/video) attached to a task (§7.6), newest first.
final capturesForTaskProvider = FutureProvider.family<List<Capture>, String>((
  ref,
  taskId,
) async {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.captures)
        ..where((c) => c.attachedType.equalsValue(AttachedType.task))
        ..where((c) => c.attachedId.equals(taskId))
        ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
      .get();
});

/// The integrity-ledger history for a task (§3.3) — status transitions in order.
final taskTransitionsProvider =
    FutureProvider.family<List<TaskTransition>, String>((ref, id) {
      return ref.watch(taskDaoProvider).transitionsFor(id);
    });

/// On-device contact participants for a task (§11).
final taskParticipantsProvider =
    FutureProvider.family<List<TaskParticipant>, String>((ref, id) {
      return ref.watch(taskDaoProvider).participantsForTask(id);
    });

final contactsServiceProvider = Provider<ContactsService>(
  (ref) => const ContactsService(),
);

/// §9 Google Tasks sync — sign-in + REST, and the import/push orchestrator.
final googleSyncServiceProvider = Provider<GoogleSyncService>((ref) {
  final service = GoogleSyncService();
  ref.onDispose(service.close);
  return service;
});

/// Whether Google is connected right now — gates connect-only affordances like
/// "Generate Google Meet link" on the event editor (§9).
final googleConnectedProvider = FutureProvider<bool>(
  (ref) => ref.watch(googleSyncServiceProvider).isConnected(),
);

final googleSyncOrchestratorProvider = Provider<GoogleSyncOrchestrator>((ref) {
  return GoogleSyncOrchestrator(
    db: ref.watch(appDatabaseProvider),
    google: ref.watch(googleSyncServiceProvider),
    idGenerator: ref.watch(uuidProvider).v4,
  );
});

final appSettingsProvider = Provider<AppSettings>(
  (ref) => AppSettings(ref.watch(appDatabaseProvider)),
);

/// §8 Saara's proactive schedule scan — overlapping tasks/events over the next
/// two weeks, each with a suggested free slot. Backs the Home conflict banner
/// and the "Check my schedule" screen.
final scheduleConflictsProvider = FutureProvider<List<ScheduleConflict>>((
  ref,
) async {
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, now.day);
  final to = from.add(const Duration(days: 14));
  final items = await ref.watch(taskDaoProvider).tasksBetween(from, to);
  const openStatuses = {
    TaskStatus.created,
    TaskStatus.started,
    TaskStatus.inProgress,
  };
  final open = items
      .where((t) => t.deletedAt == null && openStatuses.contains(t.status))
      .toList();
  // Overlaps the user has said are deliberate stay hidden — Saara flags a pair
  // once, then respects the answer instead of nagging (§8).
  final kept = await ref.watch(appSettingsProvider).keptOverlaps();
  return findConflicts(open).where((c) => !kept.contains(c.key)).toList();
});

final healthServiceProvider = Provider<HealthService>((ref) => HealthService());

/// §10 Syncs active health-source results from Health Connect into logs, so the
/// normal progress/scoring path reflects real steps/sleep/weight. Requests
/// permission on run. Returns the number of results refreshed (-1 if denied).
/// User-triggered (don't read on build — it would prompt for permission).
final healthSyncProvider = FutureProvider<int>((ref) async {
  final health = ref.watch(healthServiceProvider);
  final dao = ref.watch(areaDaoProvider);
  final results = await dao.activeHealthResults();
  if (results.isEmpty) return 0;
  if (!await health.requestAuthorization()) return -1;
  final now = DateTime.now();
  final uuid = ref.watch(uuidProvider);
  var count = 0;
  for (final r in results) {
    final period = currentPeriodKeys(r.cadence, now);
    final from = DateTime.parse(period.from);
    final to = DateTime.parse(period.to).add(const Duration(days: 1));
    final value = await health.readValue(r.metricType, from, to);
    await dao.deleteLogsForResultInRange(r.id, period.from, period.to);
    await dao.addLog(
      MeasurableLogsCompanion.insert(
        id: uuid.v4(),
        resultId: r.id,
        date: dayKey(now),
        value: value,
        createdAt: now,
      ),
    );
    count++;
  }
  // Refresh anything that shows scores.
  ref.invalidate(areaScoresProvider);
  return count;
});

/// "Value by Saara" tally (§13) — flat +1 per Saara action.
final saaraValueProvider = FutureProvider<int>(
  (ref) => ref.watch(appSettingsProvider).saaraValue(),
);

/// Overall self-effectiveness (0..100) — average of area scores that have data.
/// Placed on the reliability ladder (§13). Backs the completion wheel + the
/// listener gap card.
final overallEffectivenessProvider = FutureProvider<double>((ref) async {
  final scores = await ref.watch(areaScoresProvider.future);
  final withData = scores.where((s) => s.hasData).toList();
  if (withData.isEmpty) return 0;
  final avg =
      withData.map((s) => s.score).reduce((a, b) => a + b) / withData.length;
  return avg * 100;
});

/// The most recent committed-listener feedback across all listeners (§13).
final latestListenerFeedbackProvider = FutureProvider<ListenerFeedback?>((
  ref,
) async {
  final db = ref.watch(appDatabaseProvider);
  final rows =
      await (db.select(db.listenerFeedbacks)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .get();
  return rows.isEmpty ? null : rows.first;
});

/// Latest feedback from one listener (§13) — backs the listener card gap line.
final listenerFeedbackForProvider =
    FutureProvider.family<ListenerFeedback?, String>((ref, listenerId) async {
      final db = ref.watch(appDatabaseProvider);
      final rows =
          await (db.select(db.listenerFeedbacks)
                ..where((t) => t.listenerId.equals(listenerId))
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
                ..limit(1))
              .get();
      return rows.isEmpty ? null : rows.first;
    });

/// Committed listeners (§3.5, §13). Uses the database directly — no dedicated
/// DAO needed for this simple CRUD.
final listenersProvider = FutureProvider<List<CommittedListener>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.committedListeners).get();
});

final recurringEngineProvider = Provider<RecurringEngine>((ref) {
  final uuid = ref.watch(uuidProvider);
  return RecurringEngine(ref.watch(appDatabaseProvider), idGenerator: uuid.v4);
});

/// Runs recurring-instance materialization once when first read (e.g. on Home
/// load). Idempotent; returns the number of instances created (§4, §8).
final materializeRecurringProvider = FutureProvider<int>((ref) {
  return ref.watch(recurringEngineProvider).materializeAll();
});

/// Performance summary (today/week/month completion + streak) computed from the
/// integrity ledger over the last ~30 days (§13).
final reportSummaryProvider = FutureProvider<ReportSummary>((ref) async {
  final now = DateTime.now();
  final since = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 30));
  final transitions = await ref.watch(taskDaoProvider).transitionsSince(since);
  return buildReport(transitions, now);
});
