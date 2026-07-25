import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saara/data/database.dart';
import 'package:saara/domain/rrule_util.dart';
import 'package:saara/services/recurring_engine.dart';

/// §4 editing a repeating task, Outlook/Google style: This event · This and
/// following · All events.
///
/// The trap these tests exist for: after any scope change the engine must not
/// generate a *second* copy of a date it already owns. Every case therefore
/// re-runs materialize() and asserts the count is stable.
void main() {
  late AppDatabase db;
  late RecurringEngine engine;
  var seq = 0;

  setUp(() {
    seq = 0;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    engine = RecurringEngine(db, idGenerator: () => 'gen-${seq++}');
  });
  tearDown(() async => db.close());

  final from = DateTime(2026, 7, 21);
  final until = DateTime(2026, 7, 26);

  Future<Task> dailyWalk() async {
    const id = 'tpl-walk';
    final anchor = DateTime(2026, 7, 20, 5, 30);
    await db.taskDao.insertTask(
      TasksCompanion.insert(
        id: id,
        title: 'Morning walk',
        rrule: const Value('FREQ=DAILY'),
        scheduledStart: Value(anchor),
        dueDate: Value(anchor),
        durationMin: const Value(60),
        createdAt: anchor,
        updatedAt: anchor,
      ),
    );
    final tpl = (await db.taskDao.findById(id))!;
    await engine.materialize(tpl, from: from, until: until);
    return tpl;
  }

  group('rrule UNTIL helper', () {
    test('caps a rule and drops COUNT', () {
      final r = rruleWithUntil(
        'FREQ=DAILY;COUNT=10',
        DateTime.utc(2026, 7, 23),
      );
      expect(r, contains('UNTIL=20260723T000000Z'));
      expect(r, isNot(contains('COUNT')));
      expect(r, startsWith('FREQ=DAILY'));
    });

    test('replaces an existing UNTIL rather than adding a second', () {
      final r = rruleWithUntil(
        'FREQ=WEEKLY;UNTIL=20260101T000000Z;BYDAY=MO',
        DateTime.utc(2026, 8, 1),
      );
      expect('UNTIL='.allMatches(r).length, 1);
      expect(r, contains('BYDAY=MO'));
    });
  });

  group('a bounded series actually stops', () {
    test('no occurrence is generated past the UNTIL date', () async {
      // The "Ends" field encodes UNTIL onto the rule. The engine must honour it,
      // or the series still runs forever regardless of what the UI showed.
      final anchor = DateTime(2026, 7, 20, 5, 30);
      final end = DateTime(2026, 7, 23, 23, 59, 59); // ends after the 23rd
      await db.taskDao.insertTask(
        TasksCompanion.insert(
          id: 'tpl-bounded',
          title: 'Standup',
          rrule: Value(rruleWithUntil('FREQ=DAILY', end)),
          scheduledStart: Value(anchor),
          dueDate: Value(anchor),
          createdAt: anchor,
          updatedAt: anchor,
        ),
      );
      final tpl = (await db.taskDao.findById('tpl-bounded'))!;

      // Ask for a window that extends well past the end.
      await engine.materialize(
        tpl,
        from: DateTime(2026, 7, 20),
        until: DateTime(2026, 7, 30),
      );

      final days = (await db.taskDao.instancesOfTemplate(
        'tpl-bounded',
      )).map((t) => t.scheduledStart!.day).toSet();
      expect(days, {
        20,
        21,
        22,
        23,
      }, reason: 'generation stops on the 23rd — nothing on the 24th onward');
    });
  });

  group('All events', () {
    test('retimes every date and the rule, keeping each own date', () async {
      final tpl = await dailyWalk();
      final before = await db.taskDao.instancesOfTemplate(tpl.id);

      await db.taskDao.applyToWholeSeries(
        templateId: tpl.id,
        shared: const TasksCompanion(title: Value('Evening walk')),
        newHour: 18,
        newMinute: 0,
      );

      final after = await db.taskDao.instancesOfTemplate(tpl.id);
      expect(after, hasLength(before.length));
      for (final o in after) {
        expect(o.title, 'Evening walk');
        expect(o.scheduledStart!.hour, 18);
      }
      // Dates themselves are untouched.
      expect(
        after.map((t) => t.scheduledStart!.day).toSet(),
        before.map((t) => t.scheduledStart!.day).toSet(),
      );
      final rule = await db.taskDao.findById(tpl.id);
      expect(rule!.title, 'Evening walk');
      expect(rule.scheduledStart!.hour, 18);
    });

    test('re-running the engine adds no duplicates at the new time', () async {
      final tpl = await dailyWalk();
      await db.taskDao.applyToWholeSeries(
        templateId: tpl.id,
        shared: const TasksCompanion(title: Value('Evening walk')),
        newHour: 18,
      );
      final afterEdit = await db.taskDao.instancesOfTemplate(tpl.id);

      final fresh = (await db.taskDao.findById(tpl.id))!;
      final added = await engine.materialize(fresh, from: from, until: until);

      expect(added, 0, reason: 'the retimed dates must still be recognised');
      expect(
        await db.taskDao.instancesOfTemplate(tpl.id),
        hasLength(afterEdit.length),
      );
    });
  });

  group('This and following', () {
    test('earlier dates keep the old time; later ones move', () async {
      final tpl = await dailyWalk();
      final split = DateTime(2026, 7, 23, 5, 30); // change from the 23rd on

      final newId = await db.taskDao.splitSeriesAt(
        templateId: tpl.id,
        fromSlot: split,
        newTemplateId: 'tpl-new',
        shared: TasksCompanion.insert(
          id: 'tpl-new',
          title: 'Evening walk',
          durationMin: const Value(60),
          createdAt: split,
          updatedAt: split,
        ),
        newStart: DateTime(2026, 7, 23, 18),
      );
      expect(newId, 'tpl-new');

      // Old rule keeps only the earlier dates, at the original time.
      final oldLeft = await db.taskDao.instancesOfTemplate(tpl.id);
      expect(
        oldLeft.map((t) => t.scheduledStart!.day),
        everyElement(lessThan(23)),
      );
      for (final o in oldLeft) {
        expect(o.scheduledStart!.hour, 5);
      }
      // And it can never generate past the split again.
      final capped = await db.taskDao.findById(tpl.id);
      expect(capped!.rrule, contains('UNTIL='));
    });

    test('the new rule owns the later dates, with no overlap', () async {
      final tpl = await dailyWalk();
      final split = DateTime(2026, 7, 23, 5, 30);

      await db.taskDao.splitSeriesAt(
        templateId: tpl.id,
        fromSlot: split,
        newTemplateId: 'tpl-new',
        shared: TasksCompanion.insert(
          id: 'tpl-new',
          title: 'Evening walk',
          durationMin: const Value(60),
          createdAt: split,
          updatedAt: split,
        ),
        newStart: DateTime(2026, 7, 23, 18),
      );

      final newTpl = (await db.taskDao.findById('tpl-new'))!;
      expect(newTpl.rrule, isNot(contains('UNTIL=')));
      await engine.materialize(
        newTpl,
        from: DateTime(2026, 7, 23),
        until: until,
      );

      final fresh = await db.taskDao.instancesOfTemplate('tpl-new');
      expect(fresh, isNotEmpty);
      for (final o in fresh) {
        expect(o.title, 'Evening walk');
        expect(o.scheduledStart!.hour, 18);
      }
      // Exactly one live entry per date across BOTH rules — the whole point.
      final all = [...await db.taskDao.instancesOfTemplate(tpl.id), ...fresh];
      final days = all.map((t) => t.scheduledStart!.day).toList();
      expect(days.toSet().length, days.length, reason: 'no date served twice');
    });

    test('re-running both rules adds nothing', () async {
      final tpl = await dailyWalk();
      final split = DateTime(2026, 7, 23, 5, 30);
      await db.taskDao.splitSeriesAt(
        templateId: tpl.id,
        fromSlot: split,
        newTemplateId: 'tpl-new',
        shared: TasksCompanion.insert(
          id: 'tpl-new',
          title: 'Evening walk',
          durationMin: const Value(60),
          createdAt: split,
          updatedAt: split,
        ),
        newStart: DateTime(2026, 7, 23, 18),
      );
      final newTpl = (await db.taskDao.findById('tpl-new'))!;
      await engine.materialize(
        newTpl,
        from: DateTime(2026, 7, 23),
        until: until,
      );

      // Both rules run again, as they would on the next app open.
      final oldTpl = (await db.taskDao.findById(tpl.id))!;
      final a = await engine.materialize(oldTpl, from: from, until: until);
      final b = await engine.materialize(
        newTpl,
        from: DateTime(2026, 7, 23),
        until: until,
      );

      expect(a, 0, reason: 'the capped rule must not refill the split dates');
      expect(b, 0, reason: 'the new rule must not duplicate its own dates');
    });
  });
}
