import 'dart:io';

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
    test('a task with a list column (reminderOffsets) round-trips', () async {
      // The bug the user hit: reminderOffsets is List<int>, and jsonDecode
      // gives List<dynamic>, which the default deserializer cannot cast — the
      // whole import failed with a type-cast error.
      await deviceA
          .into(deviceA.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'reminded',
              title: 'has reminders',
              reminderOffsets: const Value([-15, -60]),
              publicationState: const Value(PublicationState.released),
              createdAt: t0,
              updatedAt: t0,
            ),
          );

      await aIntoB();

      final t = await deviceB.taskDao.findById('reminded');
      expect(t, isNotNull, reason: 'import must not fail on a list column');
      expect(t!.reminderOffsets, [-15, -60]);
    });

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

    test('a child task listed before its parent still imports', () async {
      // Foreign keys are enforced, and the merge inserts tasks in list order.
      // A recurring occurrence references its template via parentRecurringId; if
      // the occurrence is listed first, an immediate FK check would blow up the
      // whole transaction and NOTHING would sync — which is what a real bundle
      // can look like after rows are reordered by a prior merge.
      await addArea(deviceA, 'health');
      await addTask(deviceA, 'template', areaId: 'health');
      // The instance points at the template.
      await deviceA
          .into(deviceA.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'occurrence',
              title: 'occurrence',
              areaId: const Value('health'),
              parentRecurringId: const Value('template'),
              publicationState: const Value(PublicationState.released),
              createdAt: t0,
              updatedAt: t0,
            ),
          );

      final bundle = await syncA.exportBundle();
      // Force the worst order: child first.
      final tasks = (bundle['tasks'] as List).toList();
      tasks.sort((a, b) => a['id'] == 'occurrence' ? -1 : 1);
      bundle['tasks'] = tasks;

      final summary = await syncB.importBundle(bundle);

      expect(summary.tasks, 2, reason: 'both tasks must land, order be damned');
      expect(await deviceB.taskDao.findById('occurrence'), isNotNull);
      expect(await deviceB.taskDao.findById('template'), isNotNull);
    });
  });

  group('watched folder', () {
    late Directory folder;

    setUp(() => folder = Directory.systemTemp.createTempSync('saara-sync'));
    tearDown(() {
      if (folder.existsSync()) folder.deleteSync(recursive: true);
    });

    test('each device writes its own file — no shared file to clash', () async {
      await addTask(deviceA, 'a1');
      await addTask(deviceB, 'b1');

      await syncA.syncWatchedFolder(folder, 'pw');
      await syncB.syncWatchedFolder(folder, 'pw');

      final files = folder
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .toList();
      expect(files, hasLength(2), reason: 'one file per device, keyed by id');
      expect(files.every((n) => n.endsWith('.saara')), isTrue);
    });

    test('a pass writes ours, then merges every peer', () async {
      await addArea(deviceA, 'health');
      await addTask(deviceA, 'a1', title: 'from A', areaId: 'health');

      // A publishes; B syncs and should pull A in.
      await syncA.syncWatchedFolder(folder, 'pw');
      final r = await syncB.syncWatchedFolder(folder, 'pw');

      expect(r.peersRead, 1);
      expect(r.merged.tasks, 1);
      expect((await deviceB.taskDao.findById('a1'))!.title, 'from A');
    });

    test('two devices converge to the same record', () async {
      await addArea(deviceA, 'health');
      await addTask(deviceA, 'a1', areaId: 'health');
      await addArea(deviceB, 'health');
      await addTask(deviceB, 'b1', areaId: 'health');

      // A couple of rounds, as would happen over time.
      await syncA.syncWatchedFolder(folder, 'pw');
      await syncB.syncWatchedFolder(folder, 'pw');
      await syncA.syncWatchedFolder(folder, 'pw');

      final onA = (await deviceA.taskDao.allTasks()).map((t) => t.id).toSet();
      final onB = (await deviceB.taskDao.allTasks()).map((t) => t.id).toSet();
      expect(onA, {'a1', 'b1'});
      expect(onB, {'a1', 'b1'});
    });

    test('re-running a pass with no changes merges nothing new', () async {
      await addTask(deviceA, 'a1');
      await syncA.syncWatchedFolder(folder, 'pw');
      final second = await syncB.syncWatchedFolder(folder, 'pw');
      final third = await syncB.syncWatchedFolder(folder, 'pw');

      expect(second.merged.tasks, 1);
      expect(third.merged.isEmpty, isTrue, reason: 'idempotent across passes');
    });

    test('an unreadable peer file is skipped, not fatal', () async {
      await addTask(deviceA, 'a1');
      await syncA.syncWatchedFolder(folder, 'pw');
      // A junk file a cloud client might drop mid-download.
      File(
        '${folder.path}/saara-ledger-broken.saara',
      ).writeAsStringSync('not valid encrypted json');

      final r = await syncB.syncWatchedFolder(folder, 'pw');

      expect(r.peersSkipped, 1);
      expect(r.peersRead, 1, reason: 'the good file still merges');
      expect(await deviceB.taskDao.findById('a1'), isNotNull);
    });

    test('a wrong-passphrase peer is skipped, not merged as garbage', () async {
      await addTask(deviceA, 'a1');
      await syncA.syncWatchedFolder(folder, 'secretA');

      final r = await syncB.syncWatchedFolder(folder, 'differentB');

      expect(r.peersSkipped, 1);
      expect(await deviceB.taskDao.findById('a1'), isNull);
    });

    test('a missing folder is a clear error, not a silent no-op', () async {
      final gone = Directory('${folder.path}/does-not-exist');
      await expectLater(
        syncA.syncWatchedFolder(gone, 'pw'),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  group('plain export needs no password', () {
    test('a plain file imports with no passphrase at all', () async {
      await addArea(deviceA, 'health');
      await addTask(deviceA, 't1', title: 'Morning walk', areaId: 'health');
      await addEntry(deviceA, 'e1', 't1');

      final content = await syncA.exportJson();
      expect(syncB.isEncrypted(content), isFalse);

      final summary = await syncB.importFile(content); // no passphrase
      expect(summary.tasks, 1);
      expect((await deviceB.taskDao.findById('t1'))!.title, 'Morning walk');
    });

    test('importFile detects and decrypts a protected file', () async {
      await addTask(deviceA, 't1', title: 'secret');
      final content = await syncA.exportEncrypted('pw');
      expect(syncB.isEncrypted(content), isTrue);

      final summary = await syncB.importFile(content, passphrase: 'pw');
      expect(summary.tasks, 1);
    });

    test('a protected file without the password says so clearly', () async {
      await addTask(deviceA, 't1');
      final content = await syncA.exportEncrypted('pw');

      await expectLater(
        syncB.importFile(content), // forgot the password
        throwsFormatException,
      );
    });
  });

  group('encryption', () {
    test('an encrypted bundle round-trips with the right passphrase', () async {
      await addArea(deviceA, 'health');
      await addTask(deviceA, 't1', title: 'Morning walk', areaId: 'health');
      await addEntry(deviceA, 'e1', 't1');

      final armored = await syncA.exportEncrypted('correct horse battery');
      final summary = await syncB.importEncrypted(
        armored,
        'correct horse battery',
      );

      expect(summary.tasks, 1);
      expect((await deviceB.taskDao.findById('t1'))!.title, 'Morning walk');
    });

    test('the wrong passphrase is refused, not merged as garbage', () async {
      await addTask(deviceA, 't1');
      final armored = await syncA.exportEncrypted('right one');

      await expectLater(
        syncB.importEncrypted(armored, 'WRONG one'),
        throwsFormatException,
      );
      expect(await deviceB.select(deviceB.tasks).get(), isEmpty);
    });

    test('the ciphertext does not leak the plaintext', () async {
      await addTask(deviceA, 't1', title: 'a very secret errand');
      final armored = await syncA.exportEncrypted('pass');

      expect(armored.contains('secret errand'), isFalse);
      expect(armored.contains('a very secret'), isFalse);
    });

    test('a non-Saara file is rejected clearly', () async {
      await expectLater(
        syncB.importEncrypted('{"just":"some json"}', 'pass'),
        throwsFormatException,
      );
    });

    test('encryption is still idempotent through the passphrase', () async {
      await addArea(deviceA, 'health');
      await addTask(deviceA, 't1', areaId: 'health');
      await addEntry(deviceA, 'e1', 't1');

      final armored = await syncA.exportEncrypted('pw');
      await syncB.importEncrypted(armored, 'pw');
      final second = await syncB.importEncrypted(armored, 'pw');

      expect(second.isEmpty, isTrue);
    });
  });
}
