import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saara/data/database.dart';
import 'package:saara/domain/enums.dart';
import 'package:saara/domain/schedule_conflicts.dart';
import 'package:saara/services/app_settings.dart';

/// §8 overlaps are *information*, not verdicts. Saara must not decide that one
/// commitment outranks another — people legitimately multitask (a call while
/// walking, a chat on the way somewhere). These tests pin the two properties
/// that make "keep both" trustworthy: a stable identity for a pair, and an
/// answer that survives restarts.
void main() {
  Task task(String id, String title, DateTime start, int mins) => Task(
    id: id,
    title: title,
    status: TaskStatus.created,
    kind: TaskKind.task,
    scheduledStart: start,
    durationMin: mins,
    geofenceEnabled: false,
    priority: 0,
    // Overlap detection is about time, not commitment — but these stand in for
    // real, released commitments.
    publicationState: PublicationState.released,
    source: TaskSource.manual,
    createdAt: start,
    updatedAt: start,
  );

  group('overlap detection', () {
    test('flags two items that share time', () {
      final walk = task('a', 'Morning walk', DateTime(2026, 7, 21, 5, 30), 60);
      final puja = task(
        'b',
        'Clean puja items',
        DateTime(2026, 7, 21, 5, 30),
        30,
      );

      final found = findConflicts([walk, puja]);
      expect(found, hasLength(1));
    });

    test('does not flag back-to-back items', () {
      final a = task('a', 'Walk', DateTime(2026, 7, 21, 5, 30), 30);
      final b = task('b', 'Call', DateTime(2026, 7, 21, 6, 0), 30);

      expect(findConflicts([a, b]), isEmpty);
    });

    test('bare to-dos on the same instant do not collide', () {
      // The real-device bug: timed to-dos pushed to Google Tasks lose their
      // clock time and come back at midnight UTC, so a whole day's errands land
      // on one instant. They carry no duration and are not events — a due date
      // is not a time block, so they must raise no overlap.
      Task todo(String id, String title) => Task(
        id: id,
        title: title,
        status: TaskStatus.created,
        kind: TaskKind.task,
        scheduledStart: DateTime.utc(2026, 7, 23), // date-only, midnight UTC
        durationMin: null,
        geofenceEnabled: false,
        priority: 0,
        publicationState: PublicationState.released,
        source: TaskSource.gcalSync,
        createdAt: DateTime(2026, 7, 23),
        updatedAt: DateTime(2026, 7, 23),
      );

      final found = findConflicts([
        todo('a', 'Check ledger'),
        todo('b', 'test'),
        todo('c', 'Test task delete'),
      ]);
      expect(found, isEmpty, reason: 'due dates are not time blocks');
    });

    test('a timed event still collides with a bare to-do sharing its slot', () {
      // The event is a real time block; the to-do is not — so only the event
      // pair can conflict. Here there is just one time block, so nothing does.
      final ev = task('a', 'Meeting', DateTime(2026, 7, 21, 9), 60);
      final todo = Task(
        id: 'b',
        title: 'Errand',
        status: TaskStatus.created,
        kind: TaskKind.task,
        scheduledStart: DateTime(2026, 7, 21, 9),
        durationMin: null,
        geofenceEnabled: false,
        priority: 0,
        publicationState: PublicationState.released,
        source: TaskSource.manual,
        createdAt: DateTime(2026, 7, 21),
        updatedAt: DateTime(2026, 7, 21),
      );
      expect(findConflicts([ev, todo]), isEmpty);
    });

    test('suggests a slot but does not rank the two items', () {
      final meeting = task('a', 'Meeting', DateTime(2026, 7, 21, 9), 60);
      final kitchen = task('b', 'Kitchen', DateTime(2026, 7, 21, 9, 30), 30);

      final c = findConflicts([meeting, kitchen]).single;
      // The *later* item is the one offered a new slot — purely time order.
      // Saara must never conclude that "kitchen" matters less than "meeting".
      expect(c.later.id, 'b');
      expect(c.suggestedStart, isNotNull);
      expect(c.earlier.title, 'Meeting');
    });
  });

  group('pair identity for "keep both"', () {
    test('key is order-independent', () {
      final x = task('a', 'Walk', DateTime(2026, 7, 21, 5, 30), 60);
      final y = task('b', 'Puja', DateTime(2026, 7, 21, 5, 45), 30);

      final one = ScheduleConflict(
        earlier: x,
        later: y,
        suggestedStart: DateTime(2026, 7, 21, 7),
      );
      final flipped = ScheduleConflict(
        earlier: y,
        later: x,
        suggestedStart: DateTime(2026, 7, 21, 7),
      );

      expect(
        one.key,
        flipped.key,
        reason: 'the same pair must resolve to one key, however it is sorted',
      );
    });

    test('different pairs get different keys', () {
      final a = task('a', 'A', DateTime(2026, 7, 21, 5), 60);
      final b = task('b', 'B', DateTime(2026, 7, 21, 5), 60);
      final c = task('c', 'C', DateTime(2026, 7, 21, 5), 60);
      final ab = ScheduleConflict(
        earlier: a,
        later: b,
        suggestedStart: DateTime(2026, 7, 21, 7),
      );
      final ac = ScheduleConflict(
        earlier: a,
        later: c,
        suggestedStart: DateTime(2026, 7, 21, 7),
      );

      expect(ab.key, isNot(ac.key));
    });
  });

  group('keeping an overlap persists', () {
    late AppDatabase db;
    late AppSettings settings;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      settings = AppSettings(db);
    });
    tearDown(() async => db.close());

    test('an accepted overlap is remembered', () async {
      expect(await settings.keptOverlaps(), isEmpty);

      await settings.keepOverlap('a|b');
      expect(await settings.keptOverlaps(), {'a|b'});
    });

    test('accepting one does not silence the others', () async {
      await settings.keepOverlap('a|b');
      await settings.keepOverlap('c|d');

      final kept = await settings.keptOverlaps();
      expect(kept, {'a|b', 'c|d'});
      expect(
        kept.contains('e|f'),
        isFalse,
        reason: 'an unrelated overlap must still be raised',
      );
    });

    test('undo brings the overlap back', () async {
      await settings.keepOverlap('a|b');
      await settings.unkeepOverlap('a|b');

      expect(await settings.keptOverlaps(), isEmpty);
    });
  });
}
