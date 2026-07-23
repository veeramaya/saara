import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saara/data/database.dart';
import 'package:saara/domain/enums.dart';
import 'package:saara/domain/ledger_report.dart';
import 'package:saara/domain/task_service.dart';
import 'package:saara/domain/task_state_machine.dart';

/// §3.3 what the app actually **writes** to the ledger.
///
/// The schema and the fold were tested separately; this covers the join between
/// them. An entry that isn't stamped with its area, title and device is only a
/// pointer — it would read as unclassified on this device and be unreadable on
/// any other.
void main() {
  late AppDatabase db;
  late TaskService service;
  var seq = 0;
  final now = DateTime(2026, 7, 22, 9);

  setUp(() {
    seq = 0;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // An advancing clock, so entries land in a definite order. Real use spreads
    // them over minutes; without this they'd share a millisecond and the
    // draft/release boundary would be ambiguous in the test but not in life.
    var tick = 0;
    service = TaskService(
      dao: db.taskDao,
      machine: TaskStateMachine(
        idGenerator: () => 'e${seq++}',
        clock: () => now.add(Duration(minutes: tick++)),
      ),
    );
  });
  tearDown(() async => db.close());

  Future<void> addArea(String id) => db
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

  Future<Task> addTask({
    String? areaId,
    String title = 'Morning walk',
    // These tests exercise release/complete/correct, which start from a draft
    // the user then commits — so they ask for a draft explicitly.
    PublicationState publication = PublicationState.draft,
  }) async {
    if (areaId != null) await addArea(areaId);
    await db.taskDao.insertTask(
      TasksCompanion.insert(
        id: 't1',
        title: title,
        areaId: Value(areaId),
        publicationState: Value(publication),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return (await db.taskDao.findById('t1'))!;
  }

  group('every entry carries provenance', () {
    test('a status change is stamped with area, title and device', () async {
      final task = await addTask(areaId: 'health');

      await service.start(task);

      final e = (await db.taskDao.transitionsFor('t1')).single;
      expect(e.areaId, 'health');
      expect(e.titleSnapshot, 'Morning walk');
      expect(e.deviceId, await db.deviceId());
    });

    test('so is a completion', () async {
      final task = await addTask(areaId: 'health');
      await service.start(task);

      await service.complete((await db.taskDao.findById('t1'))!);

      final done = (await db.taskDao.transitionsFor(
        't1',
      )).firstWhere((e) => e.toStatus == TaskStatus.completed);
      expect(done.areaId, 'health');
      expect(done.deviceId, isNotNull);
    });
  });

  group('giving your word is recorded', () {
    test('release flips the task and posts the moment', () async {
      final task = await addTask(areaId: 'health');
      expect(task.publicationState, PublicationState.draft);

      await service.release(task);

      expect(
        (await db.taskDao.findById('t1'))!.publicationState,
        PublicationState.released,
      );
      final e = (await db.taskDao.transitionsFor('t1')).single;
      expect(e.kind, LedgerEventKind.released);
      expect(e.deviceId, isNotNull);
    });

    test('work done after release counts; before it does not', () async {
      final task = await addTask(areaId: 'health');

      // Completed while still a draft.
      await service.complete(task);
      var entries = await db.taskDao.ledgerEntriesBetween(
        now.subtract(const Duration(days: 1)),
        DateTime.now().add(const Duration(days: 1)),
      );
      expect(
        foldByArea(entries),
        isEmpty,
        reason: 'a draft must not move the books',
      );

      // Now released, and completed again after.
      final reopened = (await db.taskDao.findById('t1'))!;
      await service.release(reopened);
      await service.reopen((await db.taskDao.findById('t1'))!);
      await service.complete((await db.taskDao.findById('t1'))!);

      entries = await db.taskDao.ledgerEntriesBetween(
        now.subtract(const Duration(days: 1)),
        DateTime.now().add(const Duration(days: 1)),
      );
      expect(foldByArea(entries)['health']!.kept, 1);
    });
  });

  group('corrections adjust rather than edit', () {
    test('re-filing posts an adjusting entry and moves reporting', () async {
      final task = await addTask(areaId: 'health');
      await addArea('entertainment');
      await service.release(task);
      await service.complete((await db.taskDao.findById('t1'))!);

      await service.correctArea(
        (await db.taskDao.findById('t1'))!,
        'entertainment',
        reason: 'recreation, not health',
      );

      final correction = (await db.taskDao.transitionsFor(
        't1',
      )).firstWhere((e) => e.kind == LedgerEventKind.corrected);
      expect(correction.fromAreaId, 'health');
      expect(correction.areaId, 'entertainment');
      expect(correction.reason, 'recreation, not health');

      // The original posting still stands.
      final completion = (await db.taskDao.transitionsFor(
        't1',
      )).firstWhere((e) => e.toStatus == TaskStatus.completed);
      expect(
        completion.areaId,
        'health',
        reason: 'nothing is erased — the adjustment sits beside it',
      );

      // But reporting follows the correction.
      final entries = await db.taskDao.ledgerEntriesBetween(
        now.subtract(const Duration(days: 1)),
        DateTime.now().add(const Duration(days: 1)),
      );
      final byArea = foldByArea(entries);
      expect(byArea['entertainment']!.kept, 1);
      expect(byArea.containsKey('health'), isFalse);
    });

    test('a reason is optional and never demanded', () async {
      final task = await addTask(areaId: 'health');
      await addArea('entertainment');

      await service.correctArea(task, 'entertainment');

      final e = (await db.taskDao.transitionsFor(
        't1',
      )).firstWhere((e) => e.kind == LedgerEventKind.corrected);
      expect(e.reason, isNull);
    });

    test('re-filing to the same area records nothing', () async {
      final task = await addTask(areaId: 'health');

      await service.correctArea(task, 'health');

      expect(await db.taskDao.transitionsFor('t1'), isEmpty);
    });
  });

  group('deletion is recorded, and the past survives it', () {
    test('the miss stands after the task is deleted', () async {
      final task = await addTask(areaId: 'health');
      await service.release(task);
      await service.markMissed((await db.taskDao.findById('t1'))!);

      final doomed = (await db.taskDao.findById('t1'))!;
      await service.recordDeleted(doomed, reason: 'no longer relevant');
      await db.taskDao.softDeleteCascade('t1', instances: false);

      final entries = await db.taskDao.ledgerEntriesBetween(
        now.subtract(const Duration(days: 1)),
        DateTime.now().add(const Duration(days: 1)),
      );
      expect(
        foldByArea(entries)['health']!.broken,
        1,
        reason: 'delete removes the future, never the past',
      );
      final del = entries.firstWhere((e) => e.kind == LedgerEventKind.deleted);
      expect(del.reason, 'no longer relevant');
    });
  });

  group('the ledger is append-only', () {
    test('re-recording the same entry id is harmless', () async {
      final task = await addTask(areaId: 'health');
      await service.release(task);
      final before = await db.taskDao.transitionsFor('t1');

      // What a repeated import would do.
      await db.taskDao.recordLedgerEntry(
        TaskTransitionsCompanion.insert(
          id: before.single.id,
          taskId: 't1',
          kind: const Value(LedgerEventKind.released),
          toStatus: TaskStatus.created,
          at: before.single.at,
        ),
      );

      expect(
        await db.taskDao.transitionsFor('t1'),
        hasLength(before.length),
        reason: 'merging must be idempotent',
      );
    });
  });
}
