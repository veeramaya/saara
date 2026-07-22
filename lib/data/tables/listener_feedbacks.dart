import 'package:drift/drift.dart';

import 'committed_listeners.dart';

/// §13 relational integrity — a committed listener's summary-level view of how
/// reliably the user kept their word to them. Captured on-device (enter/share
/// based; no backend). Shown *beside* the user's self-effectiveness with the
/// gap, and used by Saara to suggest. `ratingPct` is 0..100, mapped to the same
/// reliability ladder as the self-score.
class ListenerFeedbacks extends Table {
  TextColumn get id => text()();
  TextColumn get listenerId => text().references(CommittedListeners, #id)();
  IntColumn get ratingPct => integer()(); // 0..100 the listener's view
  TextColumn get comment => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
