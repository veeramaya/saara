import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import 'areas.dart';

/// §3.2 MeasurableResult — a measurable target within an Area
/// (e.g. "Walk 8,000 steps", gte, daily, 5 days/week).
class MeasurableResults extends Table {
  TextColumn get id => text()();
  TextColumn get areaId => text().references(Areas, #id)();
  TextColumn get title => text()();
  TextColumn get metricType => textEnum<MetricType>()();
  RealColumn get targetValue => real().nullable()();
  TextColumn get comparator => textEnum<Comparator>()();
  TextColumn get cadence => textEnum<Cadence>()();
  IntColumn get daysPerCadence => integer().nullable()(); // "5 days a week"
  TextColumn get verification => textEnum<Verification>()();
  // Free-text label shown beside the number ("inches", "kg", "sessions",
  // "score"). Deliberately **not validated** — Saara isn't a unit converter;
  // the label exists so the user and their committed listener read the same
  // meaning from the same number (§3.2).
  TextColumn get unit => text().nullable()();

  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();

  // §3.2 deadline accountability. A deadline you can quietly slide is not a
  // deadline, so the first one is kept and every move is counted. The move is
  // *allowed* — plans legitimately change — but it stays visible, exactly as a
  // reopened task stays visible in the ledger.
  DateTimeColumn get originalEndDate => dateTime().nullable()();
  IntColumn get deadlineMoves => integer().withDefault(const Constant(0))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
