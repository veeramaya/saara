import 'package:drift/drift.dart';

import '../domain/enums.dart';
import 'connection.dart';
import 'converters.dart';
import 'daos/area_dao.dart';
import 'daos/task_dao.dart';
import 'seed/default_areas.dart';
import 'tables/areas.dart';
import 'tables/captures.dart';
import 'tables/committed_listeners.dart';
import 'tables/listener_feedbacks.dart';
import 'tables/measurable_logs.dart';
import 'tables/measurable_results.dart';
import 'tables/supporting.dart';
import 'tables/task_relations.dart';
import 'tables/tasks.dart';

part 'database.g.dart';

/// The encrypted local database (§1.1, §2, §3). Single source of truth for all
/// user data — Realmaya operates no backend that stores it (§1.1).
///
/// Run `dart run build_runner build` after changing any table to regenerate
/// `database.g.dart` and the DAO mixins.
@DriftDatabase(
  tables: [
    Areas,
    MeasurableResults,
    MeasurableLogs,
    Tasks,
    TaskParticipants,
    TaskTransitions,
    Captures,
    CommittedListeners,
    ListenerFeedbacks,
    SaaraGroups,
    DayLogs,
    HealthSnapshots,
    Settings,
    ApiCredentials,
  ],
  daos: [TaskDao, AreaDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openEncryptedConnection());

  /// Constructor for tests — pass an in-memory or mock [QueryExecutor].
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v2: manual measurable-result logging (§3.2/§10).
      if (from < 2) {
        await m.createTable(measurableLogs);
      }
      // v3: per-task last-synced marker for two-way Google Tasks sync (§9).
      if (from < 3) {
        await m.addColumn(tasks, tasks.lastSyncedAt);
      }
      // v4: committed-listener summary feedback (§13 relational integrity).
      if (from < 4) {
        await m.createTable(listenerFeedbacks);
      }
      // v5: task/event kind. Normalise already-imported calendar events.
      if (from < 5) {
        await m.addColumn(tasks, tasks.kind);
        await customStatement(
          "UPDATE tasks SET kind = 'event' WHERE source = 'gcalEvent'",
        );
      }
      // v6: keep the original OCR capture image with the task (§7.6).
      if (from < 6) {
        await m.addColumn(tasks, tasks.attachmentImagePath);
      }
      // v7: a Google Workspace / Drive link on a task (§11).
      if (from < 7) {
        await m.addColumn(tasks, tasks.documentLink);
      }
      // v8: optional parent event → tasks grouping (§4 meeting action items).
      if (from < 8) {
        await m.addColumn(tasks, tasks.parentEventId);
      }
      // v9: private per-event review notes (§7 retrospective, never synced).
      if (from < 9) {
        await m.addColumn(tasks, tasks.reviewNotes);
      }
      // v10: measurable-result unit label + deadline accountability (§3.2).
      if (from < 10) {
        await m.addColumn(measurableResults, measurableResults.unit);
        await m.addColumn(measurableResults, measurableResults.originalEndDate);
        await m.addColumn(measurableResults, measurableResults.deadlineMoves);
      }
      // v11: stable identity for a recurring occurrence (§4). Existing rows
      // haven't been moved yet by definition, so their current start *is* the
      // slot the rule generated — backfilling it keeps them matched and stops
      // the next expansion duplicating them.
      if (from < 11) {
        await m.addColumn(tasks, tasks.occurrenceSlot);
        await customStatement(
          'UPDATE tasks SET occurrence_slot = scheduled_start '
          'WHERE parent_recurring_id IS NOT NULL',
        );
      }
    },
    beforeOpen: (details) async {
      // Enforce FK constraints (integrity ledger relies on them, §3.3).
      await customStatement('PRAGMA foreign_keys = ON');
      // Seed starter Areas exactly once, when the DB file is first created
      // (stand-in until onboarding §20.3). Idempotent via stable seed ids.
      if (details.wasCreated) {
        await _seedDefaultAreas();
      }
    },
  );

  Future<void> _seedDefaultAreas() async {
    final now = DateTime.now();
    await batch((b) {
      for (final a in kDefaultAreas) {
        b.insert(
          areas,
          AreasCompanion.insert(
            id: a.id,
            baseCategory: a.baseCategory,
            displayName: a.displayName,
            icon: Value(a.icon),
            color: Value(a.color),
            sortOrder: Value(a.sortOrder),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    });
  }
}
