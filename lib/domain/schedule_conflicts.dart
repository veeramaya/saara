import '../data/database.dart';
import 'enums.dart';

/// §8 overlap detection. Saara scans the upcoming schedule and reports where
/// two items share time. Deterministic (no AI): precise time math.
///
/// **An overlap is information, not a verdict.** People genuinely multitask —
/// taking a call while walking, talking with a friend on the way somewhere —
/// and Saara has no business ranking one commitment above another (it cannot
/// know that kitchen work matters less than a meeting; often it doesn't). So it
/// surfaces the overlap, offers *an* alternative slot as one option among
/// several, and leaves the decision — reschedule, or keep both — to the user.
class ScheduleConflict {
  ScheduleConflict({
    required this.earlier,
    required this.later,
    required this.suggestedStart,
  });

  final Task earlier;
  final Task later;

  /// One free slot the [later] item *could* move to. A suggestion, never a
  /// recommendation — Saara does not decide which item should yield.
  final DateTime suggestedStart;

  /// Stable identity for this pair, order-independent, so "keep both" survives
  /// re-sorting, edits and restarts.
  String get key {
    final ids = [earlier.id, later.id]..sort();
    return '${ids[0]}|${ids[1]}';
  }
}

int _durMin(Task t) => t.durationMin ?? (t.kind == TaskKind.event ? 60 : 30);
DateTime _end(Task t) => t.scheduledStart!.add(Duration(minutes: _durMin(t)));

/// Only a **time block** occupies the clock. An event, or any task the user
/// gave a duration, is a span that can genuinely collide with another. A plain
/// to-do has a *due date*, not a span — two errands due the same day do not
/// "overlap", and Saara must not invent a conflict between them.
///
/// This also excludes the date-only rows Google Tasks hands back: a timed task
/// pushed to Google Tasks loses its clock time and returns at midnight UTC, so
/// a whole day's to-dos would otherwise pile onto one instant and raise a
/// cascade of phantom overlaps (they carry no duration, so they fall out here).
bool _isTimeBlock(Task t) =>
    t.scheduledStart != null &&
    (t.kind == TaskKind.event || t.durationMin != null);

/// Find overlapping pairs among scheduled items (sorted by start).
List<ScheduleConflict> findConflicts(List<Task> items) {
  final s = items.where(_isTimeBlock).toList()
    ..sort((a, b) => a.scheduledStart!.compareTo(b.scheduledStart!));
  final out = <ScheduleConflict>[];
  for (var i = 0; i < s.length; i++) {
    final a = s[i];
    final aEnd = _end(a);
    for (var j = i + 1; j < s.length; j++) {
      final b = s[j];
      if (!b.scheduledStart!.isBefore(aEnd)) break; // sorted → no more overlaps
      out.add(
        ScheduleConflict(
          earlier: a,
          later: b,
          suggestedStart: _nextFreeSlot(b, s, aEnd),
        ),
      );
    }
  }
  return out;
}

/// The earliest slot at/after [after] where [b]'s duration doesn't overlap any
/// other scheduled item.
DateTime _nextFreeSlot(Task b, List<Task> all, DateTime after) {
  final durB = _durMin(b);
  bool free(DateTime start) {
    final end = start.add(Duration(minutes: durB));
    for (final t in all) {
      if (t.id == b.id) continue;
      final ts = t.scheduledStart!;
      final te = _end(t);
      if (start.isBefore(te) && end.isAfter(ts)) return false;
    }
    return true;
  }

  var start = after;
  var guard = 0;
  while (!free(start) && guard < 96) {
    start = start.add(const Duration(minutes: 15));
    guard++;
  }
  return start;
}
