import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saara/data/database.dart';
import 'package:saara/domain/enums.dart';
import 'package:saara/domain/ledger_report.dart';

/// The hole this rework exists to close, proven end to end against a real
/// database — not just in the pure fold.
///
/// Before: scores came from current task state, so deleting a missed task
/// removed it from the denominator and your integrity score went **up**.
/// After: the miss is a recorded fact and deleting the task cannot unmake it.
void main() {
  late AppDatabase db;
  final now = DateTime(2026, 7, 22, 9);

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<void> area(String id) => db
      .into(db.areas)
      .insert(
        AreasCompanion.insert(
          id: id,
          baseCategory: BaseCategory.health,
          displayName: id,
          createdAt: now,
          updatedAt: now,
        ),
      );

  /// A released task that reached [outcome] and was recorded in the ledger.
  Future<void> commitment(
    String id, {
    required String areaId,
    required TaskStatus outcome,
  }) async {
    await db.taskDao.insertTask(
      TasksCompanion.insert(
        id: id,
        title: id,
        areaId: Value(areaId),
        status: Value(outcome),
        publicationState: const Value(PublicationState.released),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db
        .into(db.taskTransitions)
        .insert(
          TaskTransitionsCompanion.insert(
            id: 'e-$id',
            taskId: id,
            toStatus: outcome,
            areaId: Value(areaId),
            at: now,
          ),
        );
  }

  Future<double> scoreFor(String areaId) async {
    final entries = await db.taskDao.ledgerEntriesBetween(
      now.subtract(const Duration(days: 365)),
      now.add(const Duration(days: 1)),
    );
    final byArea = foldByArea(
      entries,
      legacyReleased: await db.taskDao.releasedTaskIds(),
    );
    return (byArea[areaId] ?? const LedgerScore()).ratio;
  }

  test('deleting a missed task does NOT raise the score', () async {
    await area('health');
    await commitment('kept', areaId: 'health', outcome: TaskStatus.completed);
    await commitment('missed', areaId: 'health', outcome: TaskStatus.missed);

    expect(await scoreFor('health'), closeTo(0.5, 0.0001));

    // The user deletes the evidence.
    await db.taskDao.softDeleteCascade('missed', instances: false);

    expect(
      await scoreFor('health'),
      closeTo(0.5, 0.0001),
      reason: 'the miss happened; removing the row cannot unmake it',
    );
  });

  test('a draft is invisible to scoring until released', () async {
    await area('health');
    await db.taskDao.insertTask(
      TasksCompanion.insert(
        id: 'draft',
        title: 'thinking about it',
        areaId: const Value('health'),
        status: const Value(TaskStatus.completed),
        publicationState: const Value(PublicationState.draft),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db
        .into(db.taskTransitions)
        .insert(
          TaskTransitionsCompanion.insert(
            id: 'e-draft',
            taskId: 'draft',
            toStatus: TaskStatus.completed,
            areaId: const Value('health'),
            at: now,
          ),
        );

    final entries = await db.taskDao.ledgerEntriesBetween(
      now.subtract(const Duration(days: 1)),
      now.add(const Duration(days: 1)),
    );
    final byArea = foldByArea(
      entries,
      legacyReleased: await db.taskDao.releasedTaskIds(),
    );

    expect(
      byArea,
      isEmpty,
      reason: 'thinking out loud must not flatter your score',
    );
  });

  test('reclassifying a task does not move its past postings', () async {
    await area('health');
    await area('entertainment');
    await commitment('movie', areaId: 'health', outcome: TaskStatus.completed);

    // Filed wrongly, corrected later.
    await (db.update(db.tasks)..where((t) => t.id.equals('movie'))).write(
      const TasksCompanion(areaId: Value('entertainment')),
    );

    expect(
      await scoreFor('health'),
      closeTo(1.0, 0.0001),
      reason:
          're-filing the task alone does not rewrite what was recorded — '
          'that takes an explicit correction entry',
    );
  });
}
