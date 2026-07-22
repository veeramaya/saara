import '../data/database.dart';
import 'enums.dart';

/// A deterministic performance summary computed from the integrity ledger
/// (TaskTransition rows, §3.3/§13). Pure — no I/O — so it's unit-testable.
class ReportSummary {
  ReportSummary({
    required this.todayCompleted,
    required this.todayMissed,
    required this.todayRejected,
    required this.weekCompleted,
    required this.weekMissed,
    required this.weekRejected,
    required this.monthCompleted,
    required this.monthMissed,
    required this.monthRejected,
    required this.allCompleted,
    required this.allMissed,
    required this.allRejected,
    required this.streakDays,
  });

  final int todayCompleted;
  final int todayMissed;
  final int todayRejected;
  final int weekCompleted;
  final int weekMissed;
  final int weekRejected;
  final int monthCompleted;
  final int monthMissed;
  final int monthRejected;
  final int allCompleted;
  final int allMissed;
  final int allRejected;

  /// Consecutive days ending today with at least one completion.
  final int streakDays;

  /// Kept-word rate over the week: completed / (completed + missed + rejected).
  double get weekCompletionRate {
    final total = weekCompleted + weekMissed + weekRejected;
    return total == 0 ? 0 : weekCompleted / total;
  }

  // ── Reliability on a time scale (§13) ──────────────────────────────────
  // Effectiveness = kept ÷ committed over the window, 0..100. A day can be
  // Masterful (all done) while the week is still Amateur — the same word kept
  // today weighs less against a week's worth of commitments.
  int get todayCommitted => todayCompleted + todayMissed + todayRejected;
  int get weekCommitted => weekCompleted + weekMissed + weekRejected;
  int get monthCommitted => monthCompleted + monthMissed + monthRejected;
  int get allCommitted => allCompleted + allMissed + allRejected;

  double get todayEffectiveness =>
      todayCommitted == 0 ? 0 : todayCompleted / todayCommitted * 100;
  double get weekEffectiveness =>
      weekCommitted == 0 ? 0 : weekCompleted / weekCommitted * 100;
  double get monthEffectiveness =>
      monthCommitted == 0 ? 0 : monthCompleted / monthCommitted * 100;
  double get allEffectiveness =>
      allCommitted == 0 ? 0 : allCompleted / allCommitted * 100;
}

String _dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Builds a [ReportSummary] from ledger [transitions] relative to [now].
/// Windows are rolling: week = last 7 days, month = last 30 days.
ReportSummary buildReport(List<TaskTransition> transitions, DateTime now) {
  final todayStart = DateTime(now.year, now.month, now.day);
  final weekStart = todayStart.subtract(const Duration(days: 6));
  final monthStart = todayStart.subtract(const Duration(days: 29));

  var todayCompleted = 0,
      todayMissed = 0,
      todayRejected = 0,
      weekCompleted = 0,
      weekMissed = 0,
      weekRejected = 0,
      monthCompleted = 0,
      monthMissed = 0,
      monthRejected = 0,
      allCompleted = 0,
      allMissed = 0,
      allRejected = 0;
  final completedDays = <String>{};

  for (final t in transitions) {
    final at = t.at;
    final inToday = !at.isBefore(todayStart);
    final inWeek = !at.isBefore(weekStart);
    final inMonth = !at.isBefore(monthStart);
    switch (t.toStatus) {
      case TaskStatus.completed:
        completedDays.add(_dayKey(at));
        allCompleted++;
        if (inToday) todayCompleted++;
        if (inWeek) weekCompleted++;
        if (inMonth) monthCompleted++;
      case TaskStatus.missed:
        allMissed++;
        if (inToday) todayMissed++;
        if (inWeek) weekMissed++;
        if (inMonth) monthMissed++;
      case TaskStatus.rejected:
        allRejected++;
        if (inToday) todayRejected++;
        if (inWeek) weekRejected++;
        if (inMonth) monthRejected++;
      default:
        break;
    }
  }

  // Streak: walk back from today while each day has a completion.
  var streak = 0;
  var cursor = todayStart;
  while (completedDays.contains(_dayKey(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return ReportSummary(
    todayCompleted: todayCompleted,
    todayMissed: todayMissed,
    todayRejected: todayRejected,
    weekCompleted: weekCompleted,
    weekMissed: weekMissed,
    weekRejected: weekRejected,
    monthCompleted: monthCompleted,
    monthMissed: monthMissed,
    monthRejected: monthRejected,
    allCompleted: allCompleted,
    allMissed: allMissed,
    allRejected: allRejected,
    streakDays: streak,
  );
}
