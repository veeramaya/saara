import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saara/data/database.dart';
import 'package:saara/services/recurring_engine.dart';

/// §4/§8 rescheduling ONE date of a repeating task must move that date only —
/// and must not cause the engine to re-create the original. An occurrence is
/// identified by the slot in the rule it came from, not by where the user has
/// since dragged it.
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
  final until = DateTime(2026, 7, 24);

  Future<Task> dailyTemplate() async {
    const id = 'tpl-walk';
    // Anchored before the expansion window, as a real rule is once it's a day
    // old — the rrule package requires `from >= dtStart`.
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
    return (await db.taskDao.findById(id))!;
  }

  test('a rule starting later today still generates', () async {
    // materializeAll always asks from midnight, so a task created at 08:00 for
    // 18:00 opens a window before its own start. That used to trip an assertion
    // inside the rrule package and silently produce nothing all day.
    const id = 'tpl-evening';
    final anchor = DateTime(2026, 7, 21, 18);
    await db.taskDao.insertTask(
      TasksCompanion.insert(
        id: id,
        title: 'Evening walk',
        rrule: const Value('FREQ=DAILY'),
        scheduledStart: Value(anchor),
        dueDate: Value(anchor),
        createdAt: anchor,
        updatedAt: anchor,
      ),
    );
    final tpl = (await db.taskDao.findById(id))!;

    final made = await engine.materialize(
      tpl,
      from: DateTime(2026, 7, 21), // midnight, before the 18:00 start
      until: DateTime(2026, 7, 24),
    );

    expect(made, greaterThan(0), reason: 'today\'s 18:00 date must be created');
    final live = await db.taskDao.instancesOfTemplate(id);
    expect(live.first.scheduledStart!.hour, 18);
  });

  test('expansion is idempotent — a second run adds nothing', () async {
    final tpl = await dailyTemplate();
    final first = await engine.materialize(tpl, from: from, until: until);
    final second = await engine.materialize(tpl, from: from, until: until);

    expect(first, greaterThan(0));
    expect(second, 0, reason: 're-running must not duplicate dates');
  });

  test('moving one date does not resurrect it at the old time', () async {
    final tpl = await dailyTemplate();
    await engine.materialize(tpl, from: from, until: until);

    final before = await db.taskDao.instancesOfTemplate(tpl.id);
    final day21 = before.firstWhere((t) => t.scheduledStart!.day == 21);

    // The user reschedules just this date: 5:30 AM -> 7:00 AM.
    final moved = DateTime(2026, 7, 21, 7);
    await (db.update(db.tasks)..where((t) => t.id.equals(day21.id))).write(
      TasksCompanion(
        scheduledStart: Value(moved),
        dueDate: Value(moved),
        updatedAt: Value(moved),
      ),
    );

    // The engine runs again (app reopen / day rollover).
    await engine.materialize(tpl, from: from, until: until);

    final after = await db.taskDao.instancesOfTemplate(tpl.id);
    final on21 = after.where((t) => t.scheduledStart!.day == 21).toList();

    expect(
      on21,
      hasLength(1),
      reason: 'moving a date must not leave a ghost at the original 5:30 slot',
    );
    expect(on21.single.scheduledStart, moved);
    expect(after, hasLength(before.length), reason: 'no net new rows');
  });

  test('the rest of the series is untouched by moving one date', () async {
    final tpl = await dailyTemplate();
    await engine.materialize(tpl, from: from, until: until);

    final day21 = (await db.taskDao.instancesOfTemplate(
      tpl.id,
    )).firstWhere((t) => t.scheduledStart!.day == 21);
    final moved = DateTime(2026, 7, 21, 7);
    await (db.update(db.tasks)..where((t) => t.id.equals(day21.id))).write(
      TasksCompanion(scheduledStart: Value(moved), dueDate: Value(moved)),
    );

    final others = (await db.taskDao.instancesOfTemplate(
      tpl.id,
    )).where((t) => t.scheduledStart!.day != 21);
    for (final t in others) {
      expect(
        t.scheduledStart!.hour,
        5,
        reason: 'other dates keep the original 5:30 time',
      );
    }
    // And the rule itself is unchanged.
    final rule = await db.taskDao.findById(tpl.id);
    expect(rule!.scheduledStart!.hour, 5);
    expect(rule.rrule, 'FREQ=DAILY');
  });
}
