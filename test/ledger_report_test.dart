import 'package:flutter_test/flutter_test.dart';
import 'package:saara/data/database.dart';
import 'package:saara/domain/enums.dart';
import 'package:saara/domain/ledger_report.dart';

/// §4 the scoring rules, stated as tests — `docs/LEDGER_DESIGN.md`.
///
/// These encode the decisions, not just the code: the past is not editable,
/// drafts don't count, declining is honest, silence is the failure, and a
/// correction adjusts rather than erases.
void main() {
  var seq = 0;
  final t0 = DateTime(2026, 7, 1, 9);

  TaskTransition entry({
    required String taskId,
    LedgerEventKind kind = LedgerEventKind.statusChange,
    TaskStatus toStatus = TaskStatus.completed,
    String? areaId,
    String? fromAreaId,
    int dayOffset = 0,
  }) => TaskTransition(
    id: 'e${seq++}',
    taskId: taskId,
    kind: kind,
    toStatus: toStatus,
    areaId: areaId,
    fromAreaId: fromAreaId,
    at: t0.add(Duration(days: dayOffset)),
  );

  setUp(() => seq = 0);

  group('only what you committed to is counted', () {
    test('a draft that was never released does not count', () {
      final score = foldByArea([entry(taskId: 't1', areaId: 'health')]);

      expect(score, isEmpty, reason: 'thinking out loud must cost nothing');
    });

    test('what happened before release does not count', () {
      final score = foldByArea([
        entry(taskId: 't1', areaId: 'health', dayOffset: 0),
        entry(taskId: 't1', kind: LedgerEventKind.released, dayOffset: 5),
      ]);

      expect(score, isEmpty);
    });

    test('what happened after release counts', () {
      final score = foldByArea([
        entry(taskId: 't1', kind: LedgerEventKind.released, dayOffset: 0),
        entry(taskId: 't1', areaId: 'health', dayOffset: 1),
      ]);

      expect(score['health']!.kept, 1);
    });

    test('legacy rows with no release entry still count', () {
      // They were being counted before the distinction existed. Dropping them
      // would rewrite the user's history on upgrade.
      final score = foldByArea(
        [entry(taskId: 'old', areaId: 'health')],
        legacyReleased: {'old'},
      );

      expect(score['health']!.kept, 1);
    });
  });

  group('the past is not editable', () {
    test('a disposition counts even though the task was later deleted', () {
      final score = foldByArea(
        [
          entry(taskId: 't1', areaId: 'health', toStatus: TaskStatus.missed),
          entry(taskId: 't1', kind: LedgerEventKind.deleted, dayOffset: 1),
        ],
        legacyReleased: {'t1'},
      );

      expect(
        score['health']!.broken,
        1,
        reason: 'deleting the task must not raise the score',
      );
    });
  });

  group('declining is honest; silence is the failure', () {
    test('declining does not count against you', () {
      final score = foldByArea(
        [entry(taskId: 't1', areaId: 'work', toStatus: TaskStatus.rejected)],
        legacyReleased: {'t1'},
      );

      expect(score['work']!.declined, 1);
      expect(score['work']!.answered, 0, reason: 'saying no is a real answer');
      expect(score['work']!.hasData, isFalse);
    });

    test('ignoring it does — a miss is a miss', () {
      final score = foldByArea(
        [entry(taskId: 't1', areaId: 'work', toStatus: TaskStatus.missed)],
        legacyReleased: {'t1'},
      );

      expect(score['work']!.broken, 1);
      expect(score['work']!.ratio, 0);
    });

    test('declining everything does not fake a perfect score', () {
      final score = foldByArea(
        [
          entry(taskId: 'a', areaId: 'work', toStatus: TaskStatus.rejected),
          entry(taskId: 'b', areaId: 'work', toStatus: TaskStatus.rejected),
        ],
        legacyReleased: {'a', 'b'},
      );

      expect(
        score['work']!.hasData,
        isFalse,
        reason: 'no commitments answered means no score, not 100%',
      );
    });
  });

  group('corrections adjust, they do not erase', () {
    test('reporting follows the correction', () {
      final score = foldByArea(
        [
          entry(taskId: 't1', areaId: 'health'),
          entry(
            taskId: 't1',
            kind: LedgerEventKind.corrected,
            fromAreaId: 'health',
            areaId: 'entertainment',
            dayOffset: 30,
          ),
        ],
        legacyReleased: {'t1'},
      );

      expect(score['entertainment']!.kept, 1);
      expect(score.containsKey('health'), isFalse);
    });

    test('the latest correction wins', () {
      final score = foldByArea(
        [
          entry(taskId: 't1', areaId: 'health'),
          entry(
            taskId: 't1',
            kind: LedgerEventKind.corrected,
            areaId: 'entertainment',
            dayOffset: 10,
          ),
          entry(
            taskId: 't1',
            kind: LedgerEventKind.corrected,
            areaId: 'relationships',
            dayOffset: 20,
          ),
        ],
        legacyReleased: {'t1'},
      );

      expect(score['relationships']!.kept, 1);
    });

    test('correcting one occurrence leaves its siblings alone', () {
      // The atom is the occurrence: watching a movie is recreation on Friday
      // and time with your spouse on Sunday.
      final score = foldByArea(
        [
          entry(taskId: 'fri', areaId: 'entertainment'),
          entry(taskId: 'sun', areaId: 'entertainment'),
          entry(
            taskId: 'sun',
            kind: LedgerEventKind.corrected,
            areaId: 'relationships',
            dayOffset: 1,
          ),
        ],
        legacyReleased: {'fri', 'sun'},
      );

      expect(score['entertainment']!.kept, 1);
      expect(score['relationships']!.kept, 1);
    });
  });

  group('unclassified entries', () {
    test('are kept in their own bucket, never dropped', () {
      // An invitation that arrived from outside and hasn't been filed.
      final score = foldByArea(
        [entry(taskId: 't1', areaId: null)],
        legacyReleased: {'t1'},
      );

      expect(
        score[null]!.kept,
        1,
        reason: 'dropping them would overstate the areas that are classified',
      );
    });
  });

  group('overall integrity', () {
    test('weights by volume, not by area', () {
      final score = foldByArea(
        [
          // work: 1 of 2 kept
          entry(taskId: 'w1', areaId: 'work'),
          entry(taskId: 'w2', areaId: 'work', toStatus: TaskStatus.missed),
          // health: 1 of 1 kept
          entry(taskId: 'h1', areaId: 'health'),
        ],
        legacyReleased: {'w1', 'w2', 'h1'},
      );

      // 2 kept of 3 answered — not the average of 0.5 and 1.0.
      expect(overallRatio(score), closeTo(2 / 3, 0.0001));
    });

    test('is zero when nothing has been answered', () {
      expect(overallRatio(const {}), 0);
    });
  });

  group('steps are not outcomes', () {
    test('starting something does not score', () {
      final score = foldByArea(
        [entry(taskId: 't1', areaId: 'work', toStatus: TaskStatus.started)],
        legacyReleased: {'t1'},
      );

      expect(score, isEmpty);
    });
  });
}
