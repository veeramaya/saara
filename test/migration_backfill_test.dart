import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saara/data/database.dart';
import 'package:saara/domain/enums.dart';

/// The v12 backfill (`database.dart`, `if (from < 12)`).
///
/// This is the highest-risk SQL in the project: it runs once, against real user
/// data, and its correlated subqueries can't be re-run if they get it wrong.
///
/// **Scope, stated honestly:** these exercise the backfill *statements* against
/// a database in the state the migration leaves them (columns added, values
/// still null). They do not replay a genuine v11 → v12 upgrade — that needs
/// Drift's schema-snapshot tooling, which is worth adding before the next
/// schema change.
void main() {
  late AppDatabase db;
  final now = DateTime(2026, 7, 22, 9);

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  /// A row as it looks straight after `addColumn` — new columns still empty.
  Future<void> preMigrationRow({
    required String taskId,
    required String entryId,
    String? areaId,
    String title = 'Morning walk',
  }) async {
    if (areaId != null) {
      await db
          .into(db.areas)
          .insert(
            AreasCompanion.insert(
              id: areaId,
              baseCategory: BaseCategory.health,
              displayName: areaId,
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    await db.taskDao.insertTask(
      TasksCompanion.insert(
        id: taskId,
        title: title,
        areaId: Value(areaId),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db
        .into(db.taskTransitions)
        .insert(
          TaskTransitionsCompanion.insert(
            id: entryId,
            taskId: taskId,
            toStatus: TaskStatus.completed,
            at: now,
          ),
        );
    // Blank the columns the migration is responsible for filling.
    await db.customStatement(
      'UPDATE task_transitions SET device_id = NULL, area_id = NULL, '
      'title_snapshot = NULL',
    );
    // addColumn gives existing rows the column default, which is 'draft' — so
    // that, not NULL, is the state the backfill actually inherits.
    await db.customStatement("UPDATE tasks SET publication_state = 'draft'");
  }

  /// The exact statements from the v12 migration.
  Future<void> runBackfill() async {
    await db.customStatement("UPDATE tasks SET publication_state = 'released'");
    final deviceId = await db.deviceId();
    await db.customStatement(
      'UPDATE task_transitions SET '
      "  kind = 'statusChange', "
      '  device_id = ?, '
      '  area_id = (SELECT t.area_id FROM tasks t WHERE t.id = task_id), '
      '  title_snapshot = (SELECT t.title FROM tasks t WHERE t.id = task_id)',
      [deviceId],
    );
  }

  test('existing tasks are marked released, not left as drafts', () async {
    await preMigrationRow(taskId: 't1', entryId: 'e1', areaId: 'health');

    await runBackfill();

    final t = await db.taskDao.findById('t1');
    expect(
      t!.publicationState,
      PublicationState.released,
      reason:
          'they were being counted before this existed; leaving them draft '
          'would silently erase the user history on upgrade',
    );
  });

  test('entries inherit the area and title from their task', () async {
    await preMigrationRow(
      taskId: 't1',
      entryId: 'e1',
      areaId: 'health',
      title: 'Morning walk',
    );

    await runBackfill();

    final e = (await db.taskDao.transitionsFor('t1')).single;
    expect(e.areaId, 'health');
    expect(e.titleSnapshot, 'Morning walk');
  });

  test(
    'the correlated subquery matches the right task, not the first',
    () async {
      // The bug this guards: a subquery that ignores task_id would stamp every
      // entry with the same area.
      await preMigrationRow(
        taskId: 'health-task',
        entryId: 'e1',
        areaId: 'health',
      );
      await db
          .into(db.areas)
          .insert(
            AreasCompanion.insert(
              id: 'work',
              baseCategory: BaseCategory.work,
              displayName: 'work',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db.taskDao.insertTask(
        TasksCompanion.insert(
          id: 'work-task',
          title: 'Standup',
          areaId: const Value('work'),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await db
          .into(db.taskTransitions)
          .insert(
            TaskTransitionsCompanion.insert(
              id: 'e2',
              taskId: 'work-task',
              toStatus: TaskStatus.completed,
              at: now,
            ),
          );

      await runBackfill();

      final health = (await db.taskDao.transitionsFor('health-task')).single;
      final work = (await db.taskDao.transitionsFor('work-task')).single;
      expect(health.areaId, 'health');
      expect(work.areaId, 'work', reason: 'each entry follows its own task');
      expect(work.titleSnapshot, 'Standup');
    },
  );

  test('every entry gets this device as its provenance', () async {
    await preMigrationRow(taskId: 't1', entryId: 'e1', areaId: 'health');

    await runBackfill();

    final device = await db.deviceId();
    final e = (await db.taskDao.transitionsFor('t1')).single;
    expect(
      e.deviceId,
      device,
      reason:
          'safe only because no merge has run yet — every existing entry '
          'was necessarily recorded here',
    );
  });

  test(
    'a task with no area leaves the entry unclassified, not wrong',
    () async {
      await preMigrationRow(taskId: 't1', entryId: 'e1');

      await runBackfill();

      final e = (await db.taskDao.transitionsFor('t1')).single;
      expect(e.areaId, isNull);
      expect(e.titleSnapshot, 'Morning walk');
    },
  );

  test('running the backfill twice changes nothing', () async {
    await preMigrationRow(taskId: 't1', entryId: 'e1', areaId: 'health');

    await runBackfill();
    final first = (await db.taskDao.transitionsFor('t1')).single;
    await runBackfill();
    final second = (await db.taskDao.transitionsFor('t1')).single;

    expect(second.areaId, first.areaId);
    expect(second.deviceId, first.deviceId);
    expect(second.titleSnapshot, first.titleSnapshot);
  });
}
