import '../data/database.dart';
import 'enums.dart';

/// A deterministic performance summary computed from the integrity ledger
/// (TaskTransition rows, §3.3/§13). Pure — no I/O — so it's unit-testable.
///
/// Aligned to P-Integrity (`docs/INTEGRITY_FRAMEWORK.md`):
/// **committed = completed + broken**, where **broken = missed + cancelled**.
/// A `rejected` (declined / external — an invite cancelled by its organiser) is
/// **excluded**: you didn't break a word, so it neither helps nor hurts. A
/// `cancelled` (backing out of your *own* released word) is broken and counts.
class ReportSummary {
  ReportSummary({
    required this.todayCompleted,
    required this.todayMissed,
    required this.todayCancelled,
    required this.todayRejected,
    required this.weekCompleted,
    required this.weekMissed,
    required this.weekCancelled,
    required this.weekRejected,
    required this.monthCompleted,
    required this.monthMissed,
    required this.monthCancelled,
    required this.monthRejected,
    required this.allCompleted,
    required this.allMissed,
    required this.allCancelled,
    required this.allRejected,
    required this.streakDays,
  });

  final int todayCompleted;
  final int todayMissed;
  final int todayCancelled;
  final int todayRejected;
  final int weekCompleted;
  final int weekMissed;
  final int weekCancelled;
  final int weekRejected;
  final int monthCompleted;
  final int monthMissed;
  final int monthCancelled;
  final int monthRejected;
  final int allCompleted;
  final int allMissed;
  final int allCancelled;
  final int allRejected;

  /// Consecutive days ending today with at least one completion.
  final int streakDays;

  // Broken = a no-show (missed) + backing out of your own word (cancelled).
  int get todayBroken => todayMissed + todayCancelled;
  int get weekBroken => weekMissed + weekCancelled;
  int get monthBroken => monthMissed + monthCancelled;
  int get allBroken => allMissed + allCancelled;

  /// Kept-word rate over the week: completed / (completed + broken).
  double get weekCompletionRate {
    final total = weekCompleted + weekBroken;
    return total == 0 ? 0 : weekCompleted / total;
  }

  // ── Reliability on a time scale (§13) ──────────────────────────────────
  // Effectiveness = kept ÷ committed over the window, 0..100. committed is
  // kept + broken; declined (rejected) is excluded (P-Integrity).
  int get todayCommitted => todayCompleted + todayBroken;
  int get weekCommitted => weekCompleted + weekBroken;
  int get monthCommitted => monthCompleted + monthBroken;
  int get allCommitted => allCompleted + allBroken;

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
      todayCancelled = 0,
      todayRejected = 0,
      weekCompleted = 0,
      weekMissed = 0,
      weekCancelled = 0,
      weekRejected = 0,
      monthCompleted = 0,
      monthMissed = 0,
      monthCancelled = 0,
      monthRejected = 0,
      allCompleted = 0,
      allMissed = 0,
      allCancelled = 0,
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
      case TaskStatus.cancelled:
        allCancelled++;
        if (inToday) todayCancelled++;
        if (inWeek) weekCancelled++;
        if (inMonth) monthCancelled++;
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
    todayCancelled: todayCancelled,
    todayRejected: todayRejected,
    weekCompleted: weekCompleted,
    weekMissed: weekMissed,
    weekCancelled: weekCancelled,
    weekRejected: weekRejected,
    monthCompleted: monthCompleted,
    monthMissed: monthMissed,
    monthCancelled: monthCancelled,
    monthRejected: monthRejected,
    allCompleted: allCompleted,
    allMissed: allMissed,
    allCancelled: allCancelled,
    allRejected: allRejected,
    streakDays: streak,
  );
}
