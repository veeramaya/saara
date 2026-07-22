import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import '../converters.dart';
import 'areas.dart';

/// §3.3 Task — the core commitment unit. Every status change writes a
/// [TaskTransitions] row (§3.3 / §4): that log is the integrity ledger and
/// reports are computed from it, never from mutable state alone.
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get areaId => text().nullable().references(Areas, #id)();

  TextColumn get status =>
      textEnum<TaskStatus>().withDefault(Constant(TaskStatus.created.name))();

  // §3.3 task (Google Tasks) vs event (Google Calendar). NULL = task (legacy).
  TextColumn get kind => textEnum<TaskKind>().nullable()();

  // §7.6 original capture image (OCR source) or a photo/doc attached from the
  // phone, kept on-device. Local file path.
  TextColumn get attachmentImagePath => text().nullable()();

  // §11 a Google Workspace / Drive link (Docs, Sheets, Slides, a shared file).
  // Saara doesn't create or host it — tapping opens it in Google; access is
  // governed by the user's own Google sharing.
  TextColumn get documentLink => text().nullable()();

  DateTimeColumn get scheduledStart => dateTime().nullable()();
  IntColumn get durationMin => integer().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();

  DateTimeColumn get completedAt => dateTime().nullable()();
  // Actual elapsed started→completed (§3.3, §4).
  IntColumn get timeToCompleteMin => integer().nullable()();

  TextColumn get rrule => text().nullable()(); // iCalendar RRULE
  TextColumn get parentRecurringId => text().nullable()(); // instance→template

  /// The slot in the rule this occurrence was generated for — its *identity*,
  /// fixed for life. [scheduledStart] is where the occurrence currently sits and
  /// the user may move it; this records where the rule put it.
  ///
  /// Without this the engine matched occurrences by `scheduledStart`, so moving
  /// one date left its original slot looking empty and the next expansion
  /// helpfully re-created it — a ghost at the old time (§4).
  DateTimeColumn get occurrenceSlot => dateTime().nullable()();

  // §4 optional grouping: a task (e.g. a meeting action item) can hang under a
  // parent event. NULL for standalone tasks. Area (areaId) stays the scoring
  // backbone — a child usually inherits its event's area but may override it.
  TextColumn get parentEventId => text().nullable()();

  // §7 private retrospective for an event ("how did the session go"). Kept
  // separate from `notes` because notes is the Calendar *description* and syncs
  // to Google — a review is written afterwards and stays on-device.
  TextColumn get reviewNotes => text().nullable()();

  TextColumn get meetingLink => text().nullable()();
  TextColumn get meetingProvider => textEnum<MeetingProvider>().nullable()();

  TextColumn get locationName => text().nullable()();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  BoolColumn get geofenceEnabled =>
      boolean().withDefault(const Constant(false))();

  // JSON list of minute offsets, e.g. [-15,-60]; NULL = no per-task reminder
  // (the default, §3.3 / §8).
  TextColumn get reminderOffsets =>
      text().map(const IntListConverter()).nullable()();

  // Google Tasks/Calendar sync (§9). gcal_event_id = Google Task id,
  // gcal_calendar_id = its list, gcal_etag = the Google `updated` stamp we last
  // reconciled, last_synced_at = local time of the last reconcile (for
  // last-writer-wins conflict detection).
  TextColumn get gcalEventId => text().nullable()();
  TextColumn get gcalCalendarId => text().nullable()();
  TextColumn get gcalEtag => text().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  TextColumn get source =>
      textEnum<TaskSource>().withDefault(Constant(TaskSource.manual.name))();
  IntColumn get priority => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft-delete

  @override
  Set<Column> get primaryKey => {id};
}
