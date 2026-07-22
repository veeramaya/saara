import 'package:drift/drift.dart';

import '../../domain/enums.dart';

/// §3.5 CommittedListener — a person the user chose to be witnessed by.
/// `consent_confirmed_at` records that the user confirmed the person agreed to
/// receive reports (§7.7 consent step). All delivery is via the user's own
/// channels (§1.4, §13).
class CommittedListeners extends Table {
  TextColumn get id => text()();
  TextColumn get contactLookupKey => text()();
  TextColumn get displayName => text()();
  TextColumn get channel => textEnum<ListenerChannel>()();
  TextColumn get email => text().nullable()();

  TextColumn get scope => textEnum<ListenerScope>()();
  TextColumn get scopeId => text().nullable()(); // area/task id when scoped

  TextColumn get frequency => textEnum<ListenerFrequency>()();
  BoolColumn get includeCaptures =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get consentConfirmedAt => dateTime()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
