import '../data/database.dart';
import 'enums.dart';

/// Local day key 'YYYY-MM-DD' (stable within a day, no time-zone drift).
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// The current cadence window for a result, as inclusive day-key bounds.
/// Rolling windows: daily = today; weekly = last 7 days; monthly = last 30.
({String from, String to}) currentPeriodKeys(Cadence cadence, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final from = switch (cadence) {
    Cadence.daily => today,
    Cadence.weekly => today.subtract(const Duration(days: 6)),
    Cadence.monthly => today.subtract(const Duration(days: 29)),
  };
  return (from: dayKey(from), to: dayKey(today));
}

/// Progress of a MeasurableResult over its current period (§3.2/§10).
class MeasurableProgress {
  MeasurableProgress({
    required this.aggregate,
    required this.target,
    required this.fraction,
  });

  final double aggregate;
  final double target;

  /// 0..1, respecting the comparator (gte/lte/eq).
  final double fraction;
}

MeasurableProgress computeProgress(
  MeasurableResult result,
  List<MeasurableLog> periodLogs,
) {
  final aggregate = periodLogs.fold<double>(0, (a, l) => a + l.value);
  final target = result.targetValue ?? 0;

  double frac;
  if (target == 0) {
    frac = aggregate > 0 ? 1 : 0;
  } else {
    switch (result.comparator) {
      case Comparator.gte:
        frac = aggregate / target;
      case Comparator.lte:
        frac = aggregate <= target ? 1 : target / aggregate;
      case Comparator.eq:
        frac = 1 - ((aggregate - target).abs() / target);
    }
  }
  return MeasurableProgress(
    aggregate: aggregate,
    target: target,
    fraction: frac.clamp(0.0, 1.0),
  );
}

/// Short unit label for display, derived from the metric type (§3.2).
String metricUnit(MetricType t) => switch (t) {
  MetricType.durationMin || MetricType.healthActiveMin => 'min',
  MetricType.healthSteps => 'steps',
  MetricType.healthSleepHr => 'hr',
  MetricType.healthWeight => 'kg',
  MetricType.taskCompletionPct => '%',
  MetricType.currency => '₹',
  MetricType.boolean => '',
  _ => '',
};
