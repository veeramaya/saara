import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import 'tasks.dart';

/// §3.3 TaskParticipant — on-device contact refs only; never uploaded (§1.4).
class TaskParticipants extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get contactLookupKey => text()();
  TextColumn get displayName => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// §3.3 TaskTransition — **the integrity ledger.** One row per status change
/// (§4). Reports are computed from these rows, never from mutable task state.
/// A `rescheduled` transition's `note` links to the new task instance (§4).
class TaskTransitions extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get fromStatus => textEnum<TaskStatus>().nullable()();
  TextColumn get toStatus => textEnum<TaskStatus>()();
  DateTimeColumn get at => dateTime()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
