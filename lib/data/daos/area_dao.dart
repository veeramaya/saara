import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import '../database.dart';
import '../tables/areas.dart';
import '../tables/measurable_logs.dart';
import '../tables/measurable_results.dart';

part 'area_dao.g.dart';

/// Data access for Areas, their MeasurableResults, and manual logs
/// (§3.1, §3.2, §7.5, §10).
@DriftAccessor(tables: [Areas, MeasurableResults, MeasurableLogs])
class AreaDao extends DatabaseAccessor<AppDatabase> with _$AreaDaoMixin {
  AreaDao(super.db);

  /// Active areas in display order (§7.5 — 2-column card grid).
  Future<List<Area>> activeAreas() =>
      (select(areas)
            ..where((a) => a.archived.equals(false))
            ..orderBy([(a) => OrderingTerm(expression: a.sortOrder)]))
          .get();

  Stream<List<Area>> watchActiveAreas() =>
      (select(areas)
            ..where((a) => a.archived.equals(false))
            ..orderBy([(a) => OrderingTerm(expression: a.sortOrder)]))
          .watch();

  Future<Area?> areaById(String id) =>
      (select(areas)..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<void> insertArea(AreasCompanion area) => into(areas).insert(area);

  /// Updates the area's purpose statement (§7.5).
  Future<void> setPurpose(String id, String? purpose) {
    return (update(areas)..where((a) => a.id.equals(id))).write(
      AreasCompanion(
        purposeStatement: Value(purpose),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<MeasurableResult>> resultsForArea(String areaId) =>
      (select(measurableResults)
            ..where((r) => r.areaId.equals(areaId))
            ..where((r) => r.active.equals(true)))
          .get();

  Future<void> createResult(MeasurableResultsCompanion result) =>
      into(measurableResults).insert(result);

  /// §3.2 edit a measurable result, keeping the **deadline honest**.
  ///
  /// A new deadline is computed from *today* — that's what a person means when
  /// they say "make it 10 days". But the first deadline is preserved in
  /// `original_end_date` and every move is counted, so a slipping target is
  /// visible instead of silently rewriting history. The same principle as
  /// reopening a completed task: the change is allowed, never hidden.
  Future<void> updateResult(
    MeasurableResult existing, {
    String? title,
    double? targetValue,
    String? unit,
    Cadence? cadence,
    Comparator? comparator,
    DateTime? endDate,
    bool clearEndDate = false,
  }) async {
    final movingDeadline = clearEndDate
        ? existing.endDate != null
        : (endDate != null && existing.endDate != endDate);

    await (update(
      measurableResults,
    )..where((r) => r.id.equals(existing.id))).write(
      MeasurableResultsCompanion(
        title: title == null ? const Value.absent() : Value(title),
        targetValue: targetValue == null
            ? const Value.absent()
            : Value(targetValue),
        unit: unit == null ? const Value.absent() : Value(unit),
        cadence: cadence == null ? const Value.absent() : Value(cadence),
        comparator: comparator == null
            ? const Value.absent()
            : Value(comparator),
        endDate: clearEndDate ? const Value(null) : Value(endDate),
        // Record the first deadline the moment one is first moved.
        originalEndDate: (movingDeadline && existing.originalEndDate == null)
            ? Value(existing.endDate)
            : const Value.absent(),
        deadlineMoves: movingDeadline
            ? Value(existing.deadlineMoves + 1)
            : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> archiveResult(String id) =>
      (update(measurableResults)..where((r) => r.id.equals(id))).write(
        const MeasurableResultsCompanion(active: Value(false)),
      );

  /// Logs for a result within [from, to) (used to compute the current-period
  /// aggregate). `from`/`to` are 'YYYY-MM-DD' day keys, compared as text.
  Future<List<MeasurableLog>> logsForResultInRange(
    String resultId,
    String fromDayKey,
    String toDayKey,
  ) {
    return (select(measurableLogs)
          ..where((l) => l.resultId.equals(resultId))
          ..where((l) => l.date.isBiggerOrEqualValue(fromDayKey))
          ..where((l) => l.date.isSmallerOrEqualValue(toDayKey)))
        .get();
  }

  Future<void> addLog(MeasurableLogsCompanion log) =>
      into(measurableLogs).insert(log);

  /// §10 all active health-sourced results across areas (auto-scored from
  /// Health Connect).
  Future<List<MeasurableResult>> activeHealthResults() =>
      (select(measurableResults)
            ..where((r) => r.active.equals(true))
            ..where(
              (r) => r.verification.equalsValue(Verification.healthSource),
            ))
          .get();

  /// Replace the current-period logs for a health result with a single synced
  /// value (idempotent — safe to run on every refresh).
  Future<void> deleteLogsForResultInRange(
    String resultId,
    String fromDayKey,
    String toDayKey,
  ) {
    return (delete(measurableLogs)
          ..where((l) => l.resultId.equals(resultId))
          ..where((l) => l.date.isBiggerOrEqualValue(fromDayKey))
          ..where((l) => l.date.isSmallerOrEqualValue(toDayKey)))
        .go();
  }
}
