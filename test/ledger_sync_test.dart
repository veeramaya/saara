import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saara/data/database.dart';
import 'package:saara/domain/enums.dart';
import 'package:saara/services/ledger_sync_service.dart';

/// §9 device-to-device merge through the ledger file — `docs/LEDGER_DESIGN.md`.
///
/// Two in-memory databases stand in for two devices. The property under test is
/// the one the whole design rests on: **merging is conflict-free and
/// idempotent.** Union the ledger, dedupe by id, last-writer-wins the mutable
/// rows, and importing the same bundle twice changes nothing.
void main() {
  late AppDatabase deviceA;
  late AppDatabase deviceB;
  late LedgerSyncService syncA;
  late LedgerSyncService syncB;
  final t0 = DateTime(2026, 7, 23, 9);

  setUp(() {
    deviceA = AppDatabase.forTesting(NativeDatabase.memory());
    deviceB = AppDatabase.forTesting(NativeDatabase.memory());
    syncA = LedgerSyncService(deviceA);
    syncB = LedgerSyncService(deviceB);
  });
  tearDown(() async {
    await deviceA.close();
    await deviceB.close();
  });

  Future<void> addArea(AppDatabase db, String id, {DateTime? at}) => db
      .into(db.areas)
      .insert(
        AreasCompanion.insert(
          id: id,
          baseCategory: BaseCategory.health,
          displayName: id,
          createdAt: t0,
          updatedAt: at ?? t0,
        ),
      );

  Future<void> addTask(
    AppDatabase db,
    String id, {
    String title = 'A task',
    String? areaId,
    DateTime? updatedAt,
    DateTime? deletedAt,
    TaskStatus status = TaskStatus.created,
  }) => db
      .into(db.tasks)
      .insert(
        TasksCompanion.insert(
          id: id,
          title: title,
          areaId: Value(areaId),
          status: Value(status),
          publicationState: const Value(PublicationState.released),
          deletedAt: Value(deletedAt),
          createdAt: t0,
          updatedAt: updatedAt ?? t0,
        ),
      );

  Future<void> addEntry(
    AppDatabase db,
    String id,
    String taskId, {
    String? areaId,
  }) => db
      .into(db.taskTransitions)
      .insert(
        TaskTransitionsCompanion.insert(
          id: id,
          taskId: taskId,
          toStatus: TaskStatus.completed,
          areaId: Value(areaId),
          at: t0,
        ),
      );

  Future<MergeSummary> aIntoB() async =>
      syncB.importJson(await syncA.exportJson());

  group('a fresh task travels', () {
    test('a task and its ledger entry appear on the other device', () async {
      await addArea(deviceA, 'health');
      await addTask(deviceA, 't1', title: 'Morning walk', areaId: 'health');
      await addEntry(deviceA, 'e1', 't1', areaId: 'health');

      final summary = await aIntoB();

      expect(summary.tasks, 1);
      expect(summary.ledgerEntries, 1);
      expect(summary.areas, 1);
      expect((await deviceB.taskDao.findById('t1'))!.title, 'Morning walk');
      expect(await deviceB.taskDao.transitionsFor('t1'), hasLength(1));
    });
  });

  group('merging is idempotent', () {
    test('importing the same bundle twice changes nothing', () async {
      await addArea(deviceA, 'health');
      await addTask(deviceA, 't1', areaId: 'health');
      await addEntry(deviceA, 'e1', 't1');

      final bundle = await syncA.exportJson();
      await syncB.importJson(bundle);
      final second = await syncB.importJson(bundle);

      expect(second.isEmpty, isTrue, reason: 're-import must be a no-op');
      expect(await deviceB.select(deviceB.tasks).get(), hasLength(1));
      expect(await deviceB.select(deviceB.taskTransitions).get(), hasLength(1));
    });
  });

  group('the ledger only ever grows', () {
    test('entries from both devices union; none is lost or duplicated', () async {
      // Same task worked on from both devices — different entries, same task id.
      await addArea(deviceA, 'health');
      await addTask(deviceA, 't1', areaId: 'health');
      await addEntry(deviceA, 'a-entry', 't1');

      await addArea(deviceB, 'health');
      await addTask(deviceB, 't1', areaId: 'health');
      await addEntry(deviceB, 'b-entry', 't1');

      // A → B, then B → A: both should hold both entries.
      await syncB.importJson(await syncA.exportJson());
      await syncA.importJson(await syncB.exportJson());

      final onA = await deviceA.taskDao.transitionsFor('t1');
      final onB = await deviceB.taskDao.transitionsFor('t1');
      expect(onA.map((e) => e.id).toSet(), {'a-entry', 'b-entry'});
      expect(onB.map((e) => e.id).toSet(), {'a-entry', 'b-entry'});
    });

    test('an entry we already hold is never rewritten', () async {
      await addArea(deviceA, 'health');
      await addTask(deviceA, 't1', areaId: 'health');
      await addEntry(deviceA, 'e1', 't1');
      await aIntoB();

      final before = (await deviceB.taskDao.transitionsFor('t1')).single;
      await aIntoB();
      final after = (await deviceB.taskDao.transitionsFor('t1')).single;
      expect(after.at, before.at);
    });
  });

  group('mutable rows are last-writer-wins', () {
    test('the newer edit of a task wins', () async {
      await addTask(deviceA, 't1', title: 'old title', updatedAt: t0);
      await syncB.importJson(await syncA.exportJson());

      // B edits it later.
      await (deviceB.update(
        deviceB.tasks,
      )..where((t) => t.id.equals('t1'))).write(
        TasksCompanion(
          title: const Value('new title'),
          updatedAt: Value(t0.add(const Duration(hours: 1))),
        ),
      );
      // A's stale copy must not clobber B's newer one.
      await syncB.importJson(await syncA.exportJson());

      expect((await deviceB.taskDao.findById('t1'))!.title, 'new title');
    });

    test('a delete propagates as the newer row carrying deletedAt', () async {
      await addTask(deviceA, 't1', updatedAt: t0);
      await syncB.importJson(await syncA.exportJson());
      expect(await deviceB.taskDao.findById('t1'), isNotNull);

      // A deletes it later, then syncs.
      await (deviceA.update(
        deviceA.tasks,
      )..where((t) => t.id.equals('t1'))).write(
        TasksCompanion(
          deletedAt: Value(t0.add(const Duration(hours: 2))),
          updatedAt: Value(t0.add(const Duration(hours: 2))),
        ),
      );
      await syncB.importJson(await syncA.exportJson());

      final t = await deviceB.taskDao.findById('t1');
      expect(t!.deletedAt, isNotNull, reason: 'delete must cross devices');
    });
  });

  group('safety', () {
    test('a bundle from a newer format is refused, not half-applied', () async {
      await expectLater(
        syncB.importBundle({'bundleFormat': 999, 'tasks': []}),
        throwsStateError,
      );
    });
  });
}
