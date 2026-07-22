import 'package:drift/drift.dart';

import '../../domain/enums.dart';

/// §3.1 Area. `display_name` is the user's quirky name (e.g. "Diehard"),
/// defaults to the base category name, and is shown/spoken everywhere (§19.3,
/// §20.3). `base_category` appears only as a subtitle chip on the area page.
class Areas extends Table {
  TextColumn get id => text()();
  TextColumn get baseCategory => textEnum<BaseCategory>()();
  TextColumn get displayName => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get purposeStatement => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  // Common columns (§3): all tables carry these.
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
