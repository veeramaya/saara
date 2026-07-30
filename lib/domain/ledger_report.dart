/// §4 reporting as a **fold over the ledger** — see `docs/LEDGER_DESIGN.md`.
///
/// Nothing here reads current task state. That is the whole point: scores were
/// previously computed from live rows, so deleting a missed task quietly raised
/// your score. A disposition that happened, happened.
///
/// Pure functions over entries, so they are trivially testable and produce the
/// same answer on any device holding the same ledger.
library;

import '../data/database.dart';
import 'enums.dart';

/// What one area's ledger adds up to.
class LedgerScore {
  const LedgerScore({this.kept = 0, this.broken = 0, this.declined = 0});

  /// Commitments completed.
  final int kept;

  /// Commitments missed — you gave your word and didn't.
  final int broken;

  /// Commitments **declined**. Deliberately *not* counted against you: saying
  /// no is a complete and honest answer (§4.1b-i). Silence is the failure, not
  /// refusal. Surfaced separately because declining a lot is still information
  /// worth seeing.
  final int declined;

  /// Only kept-vs-broken moves the number.
  int get answered => kept + broken;

  double get ratio => answered == 0 ? 0 : kept / answered;

  bool get hasData => answered > 0;

  LedgerScore _add({int kept = 0, int broken = 0, int declined = 0}) =>
      LedgerScore(
        kept: this.kept + kept,
        broken: this.broken + broken,
        declined: this.declined + declined,
      );

  @override
  String toString() =>
      'LedgerScore(kept: $kept, broken: $broken, declined: $declined)';
}

/// The area an entry should be **reported** under.
///
/// A correction is an adjusting entry, not an erasure (§4.3) — the original
/// posting stands, but reporting follows the correction, because the user is
/// fixing a filing error rather than flattering themselves. The latest
/// correction for a given atom wins.
///
/// Keyed by `taskId`, which *is* the occurrence: the atom is one task or one
/// occurrence, never a series (§3.2a).
Map<String, String?> effectiveAreas(Iterable<TaskTransition> entries) {
  final latest = <String, DateTime>{};
  final area = <String, String?>{};
  for (final e in entries) {
    if (e.kind != LedgerEventKind.corrected) continue;
    final seen = latest[e.taskId];
    if (seen == null || !e.at.isBefore(seen)) {
      latest[e.taskId] = e.at;
      area[e.taskId] = e.areaId;
    }
  }
  return area;
}

/// The moment each task was released, if the ledger records one.
///
/// Only what happened **after** you gave your word counts — a draft is thinking
/// out loud (§4.1a).
Map<String, DateTime> releaseTimes(Iterable<TaskTransition> entries) {
  final out = <String, DateTime>{};
  for (final e in entries) {
    if (e.kind != LedgerEventKind.released) continue;
    final seen = out[e.taskId];
    if (seen == null || e.at.isBefore(seen)) out[e.taskId] = e.at;
  }
  return out;
}

/// Folds ledger entries into a score per area.
///
/// [legacyReleased] are tasks that predate the draft/released distinction and
/// carry no `released` entry. They were being counted before this existed, so
/// they keep counting — dropping them would silently rewrite the user's history
/// the moment they upgraded, which is exactly what this whole design forbids.
///
/// The key is the area id, or `null` for entries not yet classified — which in
/// practice means invitations that arrived from outside and haven't been filed
/// (§4.1b-ii). They are reported in their own bucket rather than dropped;
/// silently discarding them would overstate the areas that *are* classified.
Map<String?, LedgerScore> foldByArea(
  Iterable<TaskTransition> entries, {
  Set<String> legacyReleased = const {},
}) {
  final corrected = effectiveAreas(entries);
  final released = releaseTimes(entries);
  final out = <String?, LedgerScore>{};

  for (final e in entries) {
    if (e.kind != LedgerEventKind.statusChange) continue;

    // Only what you actually committed to.
    final releasedAt = released[e.taskId];
    if (releasedAt == null) {
      if (!legacyReleased.contains(e.taskId)) continue;
    } else if (e.at.isBefore(releasedAt)) {
      continue; // happened while still a draft
    }

    final area = corrected.containsKey(e.taskId)
        ? corrected[e.taskId]
        : e.areaId;
    final current = out[area] ?? const LedgerScore();

    switch (e.toStatus) {
      case TaskStatus.completed:
        out[area] = current._add(kept: 1);
      case TaskStatus.missed:
      case TaskStatus.cancelled:
        // A no-show and backing out of your own word are both broken words.
        out[area] = current._add(broken: 1);
      case TaskStatus.rejected:
        // Declined / external — you didn't break a word, so it's excluded.
        out[area] = current._add(declined: 1);
      default:
        break; // started / inProgress / rescheduled are steps, not outcomes
    }
  }
  return out;
}

/// Overall integrity across every area, as a single 0–1 figure.
///
/// Computed from the **totals**, not by averaging area ratios: an area with one
/// task would otherwise weigh as heavily as an area with fifty.
double overallRatio(Map<String?, LedgerScore> byArea) {
  var kept = 0;
  var answered = 0;
  for (final s in byArea.values) {
    kept += s.kept;
    answered += s.answered;
  }
  return answered == 0 ? 0 : kept / answered;
}
