import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saara/data/database.dart';
import 'package:saara/domain/enums.dart';

/// §3.3 / §4.1a the ledger schema — see `docs/LEDGER_DESIGN.md`.
///
/// These pin the properties the whole design rests on: entries are
/// self-contained, provenance is recorded, nothing is born committed, and a
/// device id is stable.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  final now = DateTime(2026, 7, 22, 9);

  // Areas are FK-referenced and foreign keys are enforced, so they must exist.
  Future<void> addArea(String id, BaseCategory category) => db
      .into(db.areas)
      .insert(
        AreasCompanion.insert(
          id: id,
          baseCategory: category,
          displayName: id,
          createdAt: now,
          updatedAt: now,
        ),
      );

  Future<void> addTask(String id, {String? areaId}) async {
    if (areaId != null) {
      await addArea(
        areaId,
        areaId.contains('health') ? BaseCategory.health : BaseCategory.custom,
      );
    }
    await db.taskDao.insertTask(
      TasksCompanion.insert(
        id: id,
        title: 'Morning walk',
        areaId: Value(areaId),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  group('publication state', () {
    test('a task is born a draft — nothing is committed by accident', () async {
      await addTask('t1');
      final t = await db.taskDao.findById('t1');

      expect(
        t!.publicationState,
        PublicationState.draft,
        reason: 'releasing is giving your word; it must be deliberate',
      );
    });

    test('releasing is an explicit change', () async {
      await addTask('t1');
      await (db.update(db.tasks)..where((t) => t.id.equals('t1'))).write(
        const TasksCompanion(
          publicationState: Value(PublicationState.released),
        ),
      );

      final t = await db.taskDao.findById('t1');
      expect(t!.publicationState, PublicationState.released);
    });
  });

  group('device identity', () {
    test('is minted once and stays stable', () async {
      final first = await db.deviceId();
      final second = await db.deviceId();

      expect(first, isNotEmpty);
      expect(second, first, reason: 'provenance must not change under us');
    });

    test(
      'is a random local id, not derived from anything identifying',
      () async {
        final a = await db.deviceId();
        final other = AppDatabase.forTesting(NativeDatabase.memory());
        final b = await other.deviceId();
        await other.close();

        expect(a, isNot(b), reason: 'two installs, two ids');
        expect(a.length, 32, reason: '16 random bytes, hex encoded');
      },
    );
  });

  group('ledger entries are self-contained', () {
    test('carry area, title and provenance at the time', () async {
      await addTask('t1', areaId: 'area-health');
      final device = await db.deviceId();

      await db
          .into(db.taskTransitions)
          .insert(
            TaskTransitionsCompanion.insert(
              id: 'e1',
              taskId: 't1',
              kind: const Value(LedgerEventKind.statusChange),
              toStatus: TaskStatus.completed,
              areaId: const Value('area-health'),
              titleSnapshot: const Value('Morning walk'),
              deviceId: Value(device),
              at: now,
            ),
          );

      final e = (await db.taskDao.transitionsFor('t1')).single;
      expect(e.areaId, 'area-health');
      expect(e.titleSnapshot, 'Morning walk');
      expect(e.deviceId, device);
    });

    test('reclassifying the task does NOT rewrite past entries', () async {
      await addTask('t1', areaId: 'area-health');
      await db
          .into(db.taskTransitions)
          .insert(
            TaskTransitionsCompanion.insert(
              id: 'e1',
              taskId: 't1',
              toStatus: TaskStatus.completed,
              areaId: const Value('area-health'),
              at: now,
            ),
          );

      // The user re-files the task months later.
      await addArea('area-entertainment', BaseCategory.custom);
      await (db.update(db.tasks)..where((t) => t.id.equals('t1'))).write(
        const TasksCompanion(areaId: Value('area-entertainment')),
      );

      final e = (await db.taskDao.transitionsFor('t1')).single;
      expect(
        e.areaId,
        'area-health',
        reason: 'the posting keeps the account it was filed under at the time',
      );
    });

    test('a correction is an adjusting entry, not an edit', () async {
      await addTask('t1', areaId: 'area-health');
      await db
          .into(db.taskTransitions)
          .insert(
            TaskTransitionsCompanion.insert(
              id: 'e1',
              taskId: 't1',
              toStatus: TaskStatus.completed,
              areaId: const Value('area-health'),
              at: now,
            ),
          );
      // "Watching a movie belonged in Entertainment, not Health."
      await db
          .into(db.taskTransitions)
          .insert(
            TaskTransitionsCompanion.insert(
              id: 'e2',
              taskId: 't1',
              kind: const Value(LedgerEventKind.corrected),
              toStatus: TaskStatus.completed,
              fromAreaId: const Value('area-health'),
              areaId: const Value('area-entertainment'),
              reason: const Value('recreation, not health'),
              at: now.add(const Duration(days: 30)),
            ),
          );

      final all = await db.taskDao.transitionsFor('t1');
      expect(all, hasLength(2), reason: 'both postings stand — nothing erased');
      final correction = all.last;
      expect(correction.kind, LedgerEventKind.corrected);
      expect(correction.fromAreaId, 'area-health');
      expect(correction.areaId, 'area-entertainment');
      expect(correction.reason, 'recreation, not health');
    });
  });

  group('the ledger records commitment and removal', () {
    test('release is its own event, so the moment is recoverable', () async {
      await addTask('t1');
      await db
          .into(db.taskTransitions)
          .insert(
            TaskTransitionsCompanion.insert(
              id: 'e1',
              taskId: 't1',
              kind: const Value(LedgerEventKind.released),
              toStatus: TaskStatus.created,
              at: now,
            ),
          );

      final e = (await db.taskDao.transitionsFor('t1')).single;
      expect(e.kind, LedgerEventKind.released);
      expect(e.at, now, reason: 'when you gave your word is itself a fact');
    });

    test('deleting records the removal and keeps what came before', () async {
      await addTask('t1');
      await db
          .into(db.taskTransitions)
          .insert(
            TaskTransitionsCompanion.insert(
              id: 'e1',
              taskId: 't1',
              toStatus: TaskStatus.completed,
              at: now,
            ),
          );
      await db
          .into(db.taskTransitions)
          .insert(
            TaskTransitionsCompanion.insert(
              id: 'e2',
              taskId: 't1',
              kind: const Value(LedgerEventKind.deleted),
              toStatus: TaskStatus.completed,
              at: now.add(const Duration(days: 1)),
            ),
          );

      final all = await db.taskDao.transitionsFor('t1');
      expect(all.map((e) => e.kind), [
        LedgerEventKind.statusChange,
        LedgerEventKind.deleted,
      ], reason: 'delete removes the future, never the past');
    });
  });
}
