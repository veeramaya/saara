import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saara/data/database.dart';
import 'package:saara/domain/enums.dart';

/// §4.1 commitments whose moment passed with no answer.
///
/// Reported beside the score, never inside it. Folding them in would be Saara
/// deciding your silence was a failure; leaving them out entirely would make
/// silence free — and the safest way to protect a score would be to never
/// answer at all. Counting them separately keeps both honest.
void main() {
  late AppDatabase db;
  final now = DateTime(2026, 7, 23, 12);
  final yesterday = now.subtract(const Duration(days: 1));
  final tomorrow = now.add(const Duration(days: 1));

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

  Future<void> task(
    String id, {
    required DateTime when,
    String? areaId,
    TaskStatus status = TaskStatus.created,
    PublicationState publication = PublicationState.released,
    String? rrule,
    String? parentRecurringId,
  }) => db.taskDao.insertTask(
    TasksCompanion.insert(
      id: id,
      title: id,
      areaId: Value(areaId),
      status: Value(status),
      publicationState: Value(publication),
      scheduledStart: Value(when),
      dueDate: Value(when),
      rrule: Value(rrule),
      parentRecurringId: Value(parentRecurringId),
      createdAt: now,
      updatedAt: now,
    ),
  );

  test('a commitment whose moment passed unanswered is counted', () async {
    await area('health');
    await task('missed-silently', when: yesterday, areaId: 'health');

    expect(await db.taskDao.unansweredByArea(now), {'health': 1});
  });

  test('one still ahead is not', () async {
    await area('health');
    await task('later', when: tomorrow, areaId: 'health');

    expect(await db.taskDao.unansweredByArea(now), isEmpty);
  });

  test('an answered one is not — kept or broken, it was faced', () async {
    await area('health');
    await task(
      'kept',
      when: yesterday,
      areaId: 'health',
      status: TaskStatus.completed,
    );
    await task(
      'broken',
      when: yesterday,
      areaId: 'health',
      status: TaskStatus.missed,
    );
    await task(
      'declined',
      when: yesterday,
      areaId: 'health',
      status: TaskStatus.rejected,
    );

    expect(await db.taskDao.unansweredByArea(now), isEmpty);
  });

  test('a draft owes nothing — no promise was made', () async {
    await area('health');
    await task(
      'thinking',
      when: yesterday,
      areaId: 'health',
      publication: PublicationState.draft,
    );

    expect(
      await db.taskDao.unansweredByArea(now),
      isEmpty,
      reason: 'nothing was committed, so nothing is owed',
    );
  });

  test('a deleted one is not chased', () async {
    await area('health');
    await task('gone', when: yesterday, areaId: 'health');
    await db.taskDao.softDeleteCascade('gone', instances: false);

    expect(await db.taskDao.unansweredByArea(now), isEmpty);
  });

  test('a repeating rule never comes due; its occurrences do', () async {
    await area('health');
    await task(
      'the-rule',
      when: yesterday,
      areaId: 'health',
      rrule: 'FREQ=DAILY',
    );
    await task(
      'an-occurrence',
      when: yesterday,
      areaId: 'health',
      parentRecurringId: 'the-rule',
    );

    expect(
      await db.taskDao.unansweredByArea(now),
      {'health': 1},
      reason: 'the rule is a generator, not a commitment of its own',
    );
  });

  test('unclassified ones are kept, under a null key', () async {
    await task('an-invitation', when: yesterday);

    expect(await db.taskDao.unansweredByArea(now), {null: 1});
  });

  test('counts are per area', () async {
    await area('health');
    await area('work');
    await task('h1', when: yesterday, areaId: 'health');
    await task('w1', when: yesterday, areaId: 'work');
    await task('w2', when: yesterday, areaId: 'work');

    expect(await db.taskDao.unansweredByArea(now), {'health': 1, 'work': 2});
  });
}
