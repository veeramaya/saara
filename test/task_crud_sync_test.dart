import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saara/data/daos/task_dao.dart';
import 'package:saara/data/database.dart';
import 'package:saara/domain/enums.dart';
import 'package:saara/domain/task_service.dart';
import 'package:saara/domain/task_state_machine.dart';

/// End-to-end exercise of the task lifecycle against a **real** database:
/// create → edit → complete → reopen → delete → restore, plus the queries the
/// sync layer uses to decide what to push. Runs on an in-memory SQLite so it
/// tests the actual SQL, not a mock.
void main() {
  late AppDatabase db;
  late TaskDao dao;
  late TaskService service;

  DateTime at(int h) => DateTime(2026, 7, 20, h);

  Future<String> createTask(
    String title, {
    DateTime? start,
    TaskKind kind = TaskKind.task,
    String? gcalId,
  }) async {
    final id = 'id-${title.hashCode}-${kind.name}';
    final now = DateTime(2026, 7, 20, 8);
    await dao.insertTask(
      TasksCompanion.insert(
        id: id,
        title: title,
        kind: Value(kind),
        // These cover push queues and lifecycle, which only apply to
        // commitments actually made — a draft is deliberately invisible to both.
        publicationState: const Value(PublicationState.released),
        scheduledStart: Value(start),
        dueDate: Value(start),
        gcalEventId: Value(gcalId),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.taskDao;
    service = TaskService(dao: dao, machine: TaskStateMachine());
  });

  tearDown(() async => db.close());

  group('create', () {
    test('a task is stored and listed', () async {
      await createTask('Drop wife to office', start: at(9));
      final all = await dao.allTasks();
      expect(all, hasLength(1));
      expect(all.single.title, 'Drop wife to office');
    });

    test('appears on its scheduled day', () async {
      await createTask('Drop wife to office', start: at(9));
      final today = await dao.tasksForDay(DateTime(2026, 7, 20));
      expect(today, hasLength(1));
    });
  });

  group('a task with no date', () {
    // Reported as "not saving at all": leaving When = "No date/time" stores the
    // row fine, but Today and the calendar are both date-filtered, so the task
    // lands nowhere the user is looking. Saved-but-invisible reads as lost.
    test('is stored, but shows on neither Today nor the calendar', () async {
      await createTask('test for delete');

      expect(await dao.allTasks(), hasLength(1), reason: 'it really did save');
      expect(await dao.tasksForDay(DateTime(2026, 7, 20)), isEmpty);
      expect(
        await dao.tasksBetween(DateTime(2026, 7, 1), DateTime(2026, 8, 1)),
        isEmpty,
        reason: 'this is the bug — invisible everywhere the user looks',
      );
    });

    test('is picked up by the unscheduled list', () async {
      await createTask('test for delete');
      await createTask('has a date', start: at(9));

      final loose = await dao.unscheduledTasks();
      expect(loose.map((t) => t.title), ['test for delete']);
    });
  });

  group('edit', () {
    test('title and time update in place', () async {
      final id = await createTask('Drop wife', start: at(9));
      await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          title: const Value('Drop wife to office'),
          scheduledStart: Value(at(10)),
          updatedAt: Value(DateTime(2026, 7, 20, 9)),
        ),
      );
      final t = await dao.findById(id);
      expect(t!.title, 'Drop wife to office');
      expect(t.scheduledStart, at(10));
    });
  });

  group('delete', () {
    test('soft-deleted task disappears from every list', () async {
      final id = await createTask('Drop wife to office', start: at(9));
      await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(deletedAt: Value(at(11)), updatedAt: Value(at(11))),
      );

      expect(await dao.allTasks(), isEmpty, reason: 'gone from Tasks list');
      expect(
        await dao.tasksForDay(DateTime(2026, 7, 20)),
        isEmpty,
        reason: 'gone from Today',
      );
      expect(await dao.openTasks(), isEmpty, reason: 'gone from open tasks');
    });

    test('lands in Trash and restores', () async {
      final id = await createTask('Drop wife to office', start: at(9));
      await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(deletedAt: Value(at(11)), updatedAt: Value(at(11))),
      );
      expect(await dao.deletedTasks(), hasLength(1));

      await dao.restoreTask(id);
      expect(await dao.deletedTasks(), isEmpty);
      expect(await dao.allTasks(), hasLength(1));
    });

    test('a deleted task is NOT re-pushed to Google', () async {
      final id = await createTask('Drop wife to office', start: at(9));
      expect(
        await dao.tasksToPush(),
        hasLength(1),
        reason: 'unsynced task is queued to push',
      );

      await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(deletedAt: Value(at(11)), updatedAt: Value(at(11))),
      );
      expect(
        await dao.tasksToPush(),
        isEmpty,
        reason: 'deleting must not resurrect it via sync',
      );
    });

    test(
      'a synced task keeps its Google id so the delete propagates',
      () async {
        final id = await createTask('Synced', start: at(9), gcalId: 'g-123');
        await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
          TasksCompanion(deletedAt: Value(at(11)), updatedAt: Value(at(11))),
        );
        final linked = await dao.linkedTasks();
        expect(
          linked.where((t) => t.id == id),
          hasLength(1),
          reason: 'orchestrator needs it to delete the remote copy',
        );
      },
    );
  });

  group('delete a recurring task', () {
    // The reported bug: a Mon–Sat task like "Drop wife to office" is a
    // *template* plus one dated instance per day. Deleting the template stops
    // future expansion but leaves every already-generated occurrence on the
    // calendar — indistinguishable, to the user, from delete doing nothing.
    Future<String> recurringWithInstances() async {
      const templateId = 'tpl-drop-wife';
      final now = DateTime(2026, 7, 20, 8);
      await dao.insertTask(
        TasksCompanion.insert(
          id: templateId,
          title: 'Drop wife to office',
          rrule: const Value('FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA'),
          scheduledStart: Value(at(9)),
          createdAt: now,
          updatedAt: now,
        ),
      );
      for (var d = 20; d <= 22; d++) {
        await dao.insertTask(
          TasksCompanion.insert(
            id: 'inst-$d',
            title: 'Drop wife to office',
            parentRecurringId: const Value(templateId),
            scheduledStart: Value(DateTime(2026, 7, d, 9)),
            dueDate: Value(DateTime(2026, 7, d, 9)),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      return templateId;
    }

    test('deleting only the template leaves its occurrences behind', () async {
      final id = await recurringWithInstances();
      await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(deletedAt: Value(at(11))),
      );

      final left = await dao.tasksBetween(
        DateTime(2026, 7, 20),
        DateTime(2026, 7, 23),
      );
      expect(
        left,
        hasLength(3),
        reason: 'this is the bug — three occurrences survive the delete',
      );
    });

    test('cascade delete clears the template and every occurrence', () async {
      final id = await recurringWithInstances();
      await dao.softDeleteCascade(id);

      expect(
        await dao.tasksBetween(DateTime(2026, 7, 20), DateTime(2026, 7, 23)),
        isEmpty,
        reason: 'nothing may survive on the calendar',
      );
      expect(
        await dao.recurringTemplates(),
        isEmpty,
        reason: 'and no new occurrences may be generated',
      );
    });

    test('deleting one occurrence keeps the series alive', () async {
      final id = await recurringWithInstances();
      await dao.softDeleteCascade('inst-21', instances: false);

      expect(await dao.instancesOfTemplate(id), hasLength(2));
      expect(await dao.recurringTemplates(), hasLength(1));
    });

    test('all events removes the current date too (Outlook/Google)', () async {
      final id = await recurringWithInstances();
      // Delete the whole series while "on" the middle occurrence (day 21).
      await dao.softDeleteCascade(id, instances: true);

      expect(await dao.findById('inst-21'), isNotNull); // row still exists…
      expect((await dao.findById('inst-21'))!.deletedAt, isNotNull); // …deleted
      expect(await dao.instancesOfTemplate(id), isEmpty);
      expect(await dao.recurringTemplates(), isEmpty);
    });

    test(
      'this-and-following keeps earlier dates, drops this + later',
      () async {
        final id = await recurringWithInstances(); // days 20, 21, 22
        await dao.softDeleteThisAndFollowing(id, DateTime(2026, 7, 21));

        final live = await dao.instancesOfTemplate(id);
        expect(live.map((t) => t.id), [
          'inst-20',
        ], reason: 'only the past stays');
        expect(
          await dao.recurringTemplates(),
          isEmpty,
          reason: 'series stops generating new dates',
        );
      },
    );
  });

  group('google meet request', () {
    // The push side keys off "provider = Meet, no link yet". Prove an event
    // carries that signal, and that once a link exists it no longer asks.
    bool wantsMeet(Task s) =>
        s.meetingProvider == MeetingProvider.meet &&
        (s.meetingLink ?? '').isEmpty;

    test('an event set to Meet with no link requests one', () async {
      final id = 'ev-meet';
      final now = DateTime(2026, 7, 20, 8);
      await dao.insertTask(
        TasksCompanion.insert(
          id: id,
          title: 'Standup',
          kind: const Value(TaskKind.event),
          scheduledStart: Value(at(9)),
          meetingProvider: const Value(MeetingProvider.meet),
          createdAt: now,
          updatedAt: now,
        ),
      );
      expect(wantsMeet((await dao.findById(id))!), isTrue);
    });

    test('once the link is stored, it no longer requests one', () async {
      final id = 'ev-meet2';
      final now = DateTime(2026, 7, 20, 8);
      await dao.insertTask(
        TasksCompanion.insert(
          id: id,
          title: 'Standup',
          kind: const Value(TaskKind.event),
          scheduledStart: Value(at(9)),
          meetingProvider: const Value(MeetingProvider.meet),
          meetingLink: const Value('https://meet.google.com/abc-defg-hij'),
          createdAt: now,
          updatedAt: now,
        ),
      );
      expect(wantsMeet((await dao.findById(id))!), isFalse);
    });
  });

  group('recurrence syncs the rule, never the copies', () {
    // The 208-overlap incident: every materialised occurrence was pushed to
    // Google as its own task, so one daily habit became ~21 Google tasks — and
    // each device expanded *and* pushed its own set. Deletes could never line
    // up. The rule must travel once; occurrences stay local.
    Future<void> habit() async {
      final now = DateTime(2026, 7, 20, 8);
      await dao.insertTask(
        TasksCompanion.insert(
          id: 'tpl-walk',
          title: 'Morning walk',
          publicationState: const Value(PublicationState.released),
          rrule: const Value('FREQ=DAILY'),
          scheduledStart: Value(at(5)),
          createdAt: now,
          updatedAt: now,
        ),
      );
      for (var d = 20; d <= 22; d++) {
        await dao.insertTask(
          TasksCompanion.insert(
            id: 'walk-$d',
            title: 'Morning walk',
            parentRecurringId: const Value('tpl-walk'),
            scheduledStart: Value(DateTime(2026, 7, d, 5)),
            dueDate: Value(DateTime(2026, 7, d, 5)),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }

    test('occurrences are NEVER pushed to Google Tasks', () async {
      await habit();
      final pushed = await dao.tasksToPush();
      expect(
        pushed,
        isEmpty,
        reason: 'this is what multiplied into 208 duplicates',
      );
    });

    test('the rule itself goes out once, via Calendar', () async {
      await habit();
      final events = await dao.eventsToPush();
      expect(
        events.map((t) => t.id),
        ['tpl-walk'],
        reason: 'one row carrying the RRULE, not one row per date',
      );
      expect(events.single.rrule, 'FREQ=DAILY');
    });

    test('one-off tasks still push normally', () async {
      await habit();
      await createTask('Pay Bharath', start: at(9));
      final pushed = await dao.tasksToPush();
      expect(pushed.map((t) => t.title), ['Pay Bharath']);
    });

    test('a synced rule reconciles through Calendar, not Tasks', () async {
      await habit();
      await (db.update(db.tasks)..where((t) => t.id.equals('tpl-walk'))).write(
        const TasksCompanion(gcalEventId: Value('g-rule')),
      );

      expect((await dao.linkedEvents()).map((t) => t.id), ['tpl-walk']);
      expect(
        await dao.linkedTasks(),
        isEmpty,
        reason: 'the rule must not be handled by both reconcilers',
      );
    });
  });

  group('duplicate cleanup only ever targets Saara-pushed copies', () {
    // The user's condition: "ensure nothing in the google calendar which is not
    // synced by saara is deleted". Provenance is the guard — anything imported
    // from Google (gcalSync / gcalEvent) is their real calendar and is excluded.
    Future<void> add(
      String id, {
      required TaskSource source,
      String? parent,
      String? gcalId,
      TaskKind kind = TaskKind.task,
    }) async {
      final now = DateTime(2026, 7, 20, 8);
      await dao.insertTask(
        TasksCompanion.insert(
          id: id,
          title: id,
          kind: Value(kind),
          source: Value(source),
          parentRecurringId: Value(parent),
          gcalEventId: Value(gcalId),
          scheduledStart: Value(at(9)),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    test('a real Google Calendar event is never selected', () async {
      // Imported from the user's calendar, and even if it looks recurring.
      await add(
        'their-meeting',
        source: TaskSource.gcalEvent,
        gcalId: 'g-real',
        parent: 'tpl',
        kind: TaskKind.event,
      );
      await add(
        'their-gtask',
        source: TaskSource.gcalSync,
        gcalId: 'g-real2',
        parent: 'tpl',
      );

      expect(
        await dao.saaraPushedOccurrences(),
        isEmpty,
        reason: 'imported items must be untouchable',
      );
    });

    test('only Saara-created per-date copies are selected', () async {
      await add(
        'saara-copy',
        source: TaskSource.manual,
        parent: 'tpl',
        gcalId: 'g-junk',
      );
      await add(
        'their-meeting',
        source: TaskSource.gcalEvent,
        gcalId: 'g-real',
        parent: 'tpl',
      );

      final strays = await dao.saaraPushedOccurrences();
      expect(strays.map((t) => t.id), ['saara-copy']);
    });

    test('one-offs and rules are not touched, only generated copies', () async {
      // A pushed one-off (no parent) is legitimate — it must survive.
      await add('one-off', source: TaskSource.manual, gcalId: 'g-oneoff');
      // A synced rule is legitimate too.
      await add('the-rule', source: TaskSource.manual, gcalId: 'g-rule');

      expect(await dao.saaraPushedOccurrences(), isEmpty);
    });

    test('unlinking leaves the local occurrence intact', () async {
      await add(
        'saara-copy',
        source: TaskSource.manual,
        parent: 'tpl',
        gcalId: 'g-junk',
      );
      await dao.unlinkFromGoogle('saara-copy');

      final t = await dao.findById('saara-copy');
      expect(t, isNotNull, reason: 'the local date stays — only the link goes');
      expect(t!.gcalEventId, isNull);
      expect(
        await dao.saaraPushedOccurrences(),
        isEmpty,
        reason: 'and it is never re-selected',
      );
    });
  });

  group('lifecycle', () {
    test('complete then reopen clears the completion', () async {
      final id = await createTask('Drop wife to office', start: at(9));
      var task = (await dao.findById(id))!;

      await service.start(task);
      task = (await dao.findById(id))!;
      expect(task.status, TaskStatus.started);

      await service.complete(task);
      task = (await dao.findById(id))!;
      expect(task.status, TaskStatus.completed);
      expect(task.completedAt, isNotNull);

      await service.reopen(task);
      task = (await dao.findById(id))!;
      expect(task.status, TaskStatus.started);
      expect(
        task.completedAt,
        isNull,
        reason: 'reopening must clear the stamp so a later completion is clean',
      );

      // The ledger keeps the whole story.
      final history = await dao.transitionsFor(id);
      expect(
        history.map((t) => t.toStatus),
        containsAll([TaskStatus.started, TaskStatus.completed]),
      );
    });
  });

  group('sync queues', () {
    test('events and tasks push through separate queues', () async {
      await createTask('A todo', start: at(9));
      await createTask('A meeting', start: at(10), kind: TaskKind.event);

      final tasks = await dao.tasksToPush();
      final events = await dao.eventsToPush();
      expect(tasks.map((t) => t.title), ['A todo']);
      expect(events.map((t) => t.title), ['A meeting']);
    });

    test('an already-synced task is not pushed again', () async {
      await createTask('Synced', start: at(9), gcalId: 'g-1');
      expect(await dao.tasksToPush(), isEmpty);
    });
  });
}
