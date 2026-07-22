import 'package:drift/drift.dart';

import 'measurable_results.dart';

/// A single logged value against a MeasurableResult (manual_log verification,
/// §3.2/§10). Progress is computed by aggregating these over the result's
/// current cadence window. Added in schema v2.
class MeasurableLogs extends Table {
  TextColumn get id => text()();
  TextColumn get resultId => text().references(MeasurableResults, #id)();
  TextColumn get date => text()(); // local day 'YYYY-MM-DD'
  RealColumn get value => real()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
