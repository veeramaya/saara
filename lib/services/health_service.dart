import 'package:health/health.dart';

import '../domain/enums.dart';

/// §10 Health Connect reader. On Android, reads steps / sleep / weight from
/// Health Connect (which Samsung Health, Fitbit, Google Fit, etc. write into),
/// so health-verified results score themselves. Read-only; nothing leaves the
/// device (§1.1).
class HealthService {
  final Health _health = Health();

  // The metric types we support reading today.
  static const _map = <MetricType, HealthDataType>{
    MetricType.healthSteps: HealthDataType.STEPS,
    MetricType.healthSleepHr: HealthDataType.SLEEP_ASLEEP,
    MetricType.healthWeight: HealthDataType.WEIGHT,
  };

  static List<HealthDataType> get _types => _map.values.toList();

  bool _configured = false;
  Future<void> _ensure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Ask the user (via Health Connect) for read access to the supported types.
  Future<bool> requestAuthorization() async {
    await _ensure();
    final perms = _types.map((_) => HealthDataAccess.READ).toList();
    return _health.requestAuthorization(_types, permissions: perms);
  }

  Future<bool> hasPermissions() async {
    await _ensure();
    return (await _health.hasPermissions(
          _types,
          permissions: _types.map((_) => HealthDataAccess.READ).toList(),
        )) ??
        false;
  }

  /// The value for [metric] over [from, to]: total steps, total sleep hours, or
  /// latest weight. Returns 0 if unavailable.
  Future<double> readValue(
    MetricType metric,
    DateTime from,
    DateTime to,
  ) async {
    await _ensure();
    if (metric == MetricType.healthSteps) {
      final s = await _health.getTotalStepsInInterval(from, to);
      return (s ?? 0).toDouble();
    }
    final type = _map[metric];
    if (type == null) return 0;
    final points = await _health.getHealthDataFromTypes(
      types: [type],
      startTime: from,
      endTime: to,
    );
    if (points.isEmpty) return 0;

    if (metric == MetricType.healthWeight) {
      // Latest reading, not a sum.
      final v = points.last.value;
      return v is NumericHealthValue ? v.numericValue.toDouble() : 0;
    }
    var sum = 0.0;
    for (final p in points) {
      final v = p.value;
      if (v is NumericHealthValue) sum += v.numericValue.toDouble();
    }
    // Sleep points are minutes in Health Connect → hours.
    if (metric == MetricType.healthSleepHr) return sum / 60.0;
    return sum;
  }
}
