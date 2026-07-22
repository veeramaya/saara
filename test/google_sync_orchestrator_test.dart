import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saara/data/database.dart';
import 'package:saara/domain/enums.dart';
import 'package:saara/services/google/google_sync_orchestrator.dart';
import 'package:saara/services/google/google_sync_service.dart';

import 'fakes/fake_google.dart';

/// §9 the reconcile, against a fake Google.
///
/// Every sync bug this project hit was found in production because this layer
/// had no seam to test against. These cover the ones that actually happened —
/// they are regressions, not hypotheticals.
void main() {
  late AppDatabase db;
  late FakeGoogle google;
  late GoogleSyncOrchestrator sync;
  var seq = 0;

  final now = DateTime(2026, 7, 22, 9);

  setUp(() {
    seq = 0;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    google = FakeGoogle();
    sync = GoogleSyncOrchestrator(
      db: db,
      google: google,
      idGenerator: () => 'local-${seq++}',
    );
  });
  tearDown(() async => db.close());

  Future<void> task(
    String id, {
    String title = 'A task',
    TaskKind kind = TaskKind.task,
    DateTime? start,
    String? rrule,
    String? parentRecurringId,
    String? gcalEventId,
    MeetingProvider? meetingProvider,
    // Most of these tests are about things already committed to, so released is
    // the useful default here; draft is exercised explicitly below.
    PublicationState publicationState = PublicationState.released,
  }) => db.taskDao.insertTask(
    TasksCompanion.insert(
      id: id,
      title: title,
      kind: Value(kind),
      scheduledStart: Value(start),
      dueDate: Value(start),
      rrule: Value(rrule),
      parentRecurringId: Value(parentRecurringId),
      gcalEventId: Value(gcalEventId),
      meetingProvider: Value(meetingProvider),
      publicationState: Value(publicationState),
      createdAt: now,
      updatedAt: now,
    ),
  );

  group('recurrence syncs the rule, never the copies', () {
    test('a habit pushes ONE calendar entry, not one per date', () async {
      // The 208-duplicate incident, as a test.
      await task(
        'rule',
        title: 'Morning walk',
        start: DateTime(2026, 7, 22, 5, 30),
        rrule: 'FREQ=DAILY',
      );
      for (var d = 22; d <= 26; d++) {
        await task(
          'occ-$d',
          title: 'Morning walk',
          start: DateTime(2026, 7, d, 5, 30),
          parentRecurringId: 'rule',
        );
      }

      await sync.syncAll();

      expect(
        google.pushedTaskTitles,
        isEmpty,
        reason: 'per-date copies must never reach Google Tasks',
      );
      expect(google.pushedEventTitles, [
        'Morning walk',
      ], reason: 'the rule travels once');
      expect(google.pushedRecurrences, ['FREQ=DAILY']);
    });

    test('a one-off task still pushes normally', () async {
      await task('t1', title: 'Pay Bharath', start: now);

      await sync.syncAll();

      expect(google.pushedTaskTitles, ['Pay Bharath']);
    });

    test('syncing twice pushes nothing the second time', () async {
      await task('t1', title: 'Pay Bharath', start: now);

      await sync.syncAll();
      final afterFirst = google.tasks.length;
      await sync.syncAll();

      expect(
        google.tasks.length,
        afterFirst,
        reason: 'sync must be idempotent — this is how duplicates start',
      );
    });
  });

  group('drafts stay off Google', () {
    test('a draft task is never pushed', () async {
      await task(
        't1',
        title: 'Still thinking',
        start: now,
        publicationState: PublicationState.draft,
      );

      await sync.syncAll();

      expect(
        google.pushedTaskTitles,
        isEmpty,
        reason: 'half-formed thinking must not appear on a shared calendar',
      );
    });

    test('a draft event is never pushed', () async {
      await task(
        'ev',
        title: 'Maybe a workshop',
        kind: TaskKind.event,
        start: now,
        publicationState: PublicationState.draft,
      );

      await sync.syncAll();

      expect(google.pushedEventTitles, isEmpty);
    });

    test('releasing it later does push it', () async {
      await task(
        't1',
        title: 'Still thinking',
        start: now,
        publicationState: PublicationState.draft,
      );
      await sync.syncAll();
      expect(google.pushedTaskTitles, isEmpty);

      await db.taskDao.setPublicationState('t1', PublicationState.released);
      await sync.syncAll();

      expect(google.pushedTaskTitles, ['Still thinking']);
    });
  });

  group('invitations arrive released', () {
    test('an incoming event counts — you owe a response', () async {
      google.seedIncomingEvent(
        title: 'Product review',
        start: DateTime(2026, 7, 23, 15),
      );

      await sync.syncAll();

      final imported = (await db.taskDao.allTasks()).firstWhere(
        (t) => t.title == 'Product review',
      );
      expect(
        imported.publicationState,
        PublicationState.released,
        reason: 'an unanswered invitation lacks your listening with others',
      );
    });
  });

  group('deletes propagate', () {
    test('a locally deleted task is removed from Google', () async {
      await task('t1', title: 'Drop wife to office', start: now);
      await sync.syncAll();
      expect(google.tasks, isNotEmpty);

      await db.taskDao.softDeleteCascade('t1', instances: false);
      await sync.syncAll();

      expect(google.tasks, isEmpty, reason: 'deleting here must delete there');
    });

    test('a deleted task is never re-pushed', () async {
      await task('t1', title: 'Gone', start: now);
      await db.taskDao.softDeleteCascade('t1', instances: false);

      await sync.syncAll();

      expect(google.pushedTaskTitles, isEmpty);
    });
  });

  group('incoming from Google', () {
    test('an event someone else created is imported', () async {
      google.seedIncomingEvent(
        title: 'Product review',
        start: DateTime(2026, 7, 23, 15),
      );

      await sync.syncAll();

      final local = await db.taskDao.allTasks();
      expect(local.map((t) => t.title), contains('Product review'));
    });

    test('importing twice does not duplicate it', () async {
      google.seedIncomingEvent(
        title: 'Product review',
        start: DateTime(2026, 7, 23, 15),
      );

      await sync.syncAll();
      await sync.syncAll();

      final local = await db.taskDao.allTasks();
      expect(
        local.where((t) => t.title == 'Product review'),
        hasLength(1),
        reason: 'the import must key off the Google id, not re-add each pass',
      );
    });
  });

  group('Google Meet', () {
    test('ensureMeetLink asks for a conference and stores the link', () async {
      await task(
        'ev',
        title: 'Standup',
        kind: TaskKind.event,
        start: DateTime(2026, 7, 23, 10),
        meetingProvider: MeetingProvider.meet,
      );

      final link = await sync.ensureMeetLink('ev');

      expect(google.meetRequests, ['ev'], reason: 'keyed by the task id');
      expect(link, contains('meet.google.com'));

      final saved = await db.taskDao.findById('ev');
      expect(saved!.meetingLink, link);
    });

    test('an event that already has a link is left alone', () async {
      await task(
        'ev',
        title: 'Standup',
        kind: TaskKind.event,
        start: DateTime(2026, 7, 23, 10),
        meetingProvider: MeetingProvider.meet,
      );
      await (db.update(db.tasks)..where((t) => t.id.equals('ev'))).write(
        const TasksCompanion(meetingLink: Value('https://meet.google.com/x')),
      );

      await sync.ensureMeetLink('ev');

      expect(
        google.meetRequests,
        isEmpty,
        reason: 'no second conference for the same event',
      );
    });
  });

  group('duplicate cleanup', () {
    test('removes Saara-pushed per-date copies and nothing else', () async {
      // A leftover from the old behaviour: an occurrence that carries a Google
      // id because a previous version pushed it.
      await task(
        'occ',
        title: 'Morning walk',
        start: now,
        parentRecurringId: 'rule',
        gcalEventId: 'gt-junk',
      );
      google.tasks['gt-junk'] = GTaskStub.make('gt-junk', 'Morning walk');
      // And a real event the user created directly in Google.
      google.seedIncomingEvent(title: 'Their meeting', start: now);

      final removed = await sync.cleanupStrayOccurrences();

      expect(removed, 1);
      expect(google.tasks.containsKey('gt-junk'), isFalse);
      expect(
        google.events.values.map((e) => e.title),
        contains('Their meeting'),
        reason: 'anything Saara did not push must be untouchable',
      );
    });
  });
}

/// Tiny helper so a test can seed a Google *task* directly.
class GTaskStub {
  static GTask make(String id, String title) => GTask(
    id: id,
    listId: 'list-1',
    title: title,
    updated: DateTime(2026, 7, 21).toIso8601String(),
  );
}
