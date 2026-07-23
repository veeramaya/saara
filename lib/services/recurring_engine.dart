import 'package:drift/drift.dart';
import 'package:rrule/rrule.dart';

import '../data/database.dart';
import '../domain/enums.dart';

/// §4 / §8 recurring engine. Deterministic (Tier 0): expands a template task's
/// iCalendar RRULE into concrete instances for the upcoming horizon.
///
/// Rules honored (§4):
/// - Recurring *templates* never change status; each generated instance does.
/// - Instances link back to their template via `parent_recurring_id`.
/// - Generation is idempotent: an instance is only created if one doesn't
///   already exist for that (template, scheduled_start).
class RecurringEngine {
  RecurringEngine(this.db, {String Function()? idGenerator})
    : _newId = idGenerator ?? _fallbackId;

  final AppDatabase db;
  final String Function() _newId;

  /// Expands every recurring template into instances over the next
  /// [horizonDays]. Idempotent — safe to call on each app open / day rollover
  /// (§8). Returns the total number of new instances inserted.
  Future<int> materializeAll({int horizonDays = 21}) async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final until = from.add(Duration(days: horizonDays));
    final templates = await db.taskDao.recurringTemplates();
    var total = 0;
    for (final template in templates) {
      total += await materialize(template, from: from, until: until);
    }
    return total;
  }

  /// Materializes instances for [template] whose start falls within
  /// [from, until]. Returns the number of new instances inserted.
  Future<int> materialize(
    Task template, {
    required DateTime from,
    required DateTime until,
  }) async {
    if (template.rrule == null || template.scheduledStart == null) return 0;

    final occurrences = expand(
      rruleText: template.rrule!,
      dtStart: template.scheduledStart!,
      from: from,
      until: until,
    );

    var inserted = 0;
    for (final start in occurrences) {
      final exists = await _instanceExists(template.id, start);
      if (exists) continue;
      await db.into(db.tasks).insert(_instanceOf(template, start));
      inserted++;
    }
    return inserted;
  }

  /// Pure RRULE expansion. Exposed for unit tests. Returns local DateTimes.
  List<DateTime> expand({
    required String rruleText,
    required DateTime dtStart,
    required DateTime from,
    required DateTime until,
  }) {
    final normalized = rruleText.startsWith('RRULE:')
        ? rruleText
        : 'RRULE:$rruleText';
    final rule = RecurrenceRule.fromString(normalized);
    // A window that opens *before* the rule starts is legal from the caller's
    // point of view — materializeAll always asks from midnight — but the rrule
    // package asserts `after >= start` and would throw, silently killing
    // generation for any rule whose first occurrence is later the same day.
    // Clamp instead: the rule cannot produce anything before its own start.
    final effectiveFrom = from.isBefore(dtStart) ? dtStart : from;
    if (until.isBefore(effectiveFrom)) return const [];
    // The rrule package computes in UTC; convert around the boundary.
    return rule
        .getInstances(
          start: dtStart.toUtc(),
          after: effectiveFrom.toUtc(),
          before: until.toUtc(),
          includeAfter: true,
          includeBefore: true,
        )
        .map((d) => d.toLocal())
        .toList();
  }

  /// Has this *slot* of the rule already been generated?
  ///
  /// Matched on [occurrenceSlot], never on `scheduledStart`: the user is free to
  /// move a single date, and moving it must not make its slot look vacant — that
  /// is what caused the engine to re-create the occurrence at its original time.
  /// Deleted rows still count, so deleting one date doesn't bring it back either.
  ///
  /// `occurrenceSlot IS NULL` covers rows written before v11 (backfilled by the
  /// migration, but a pre-v11 row that was already moved falls back to its start).
  Future<bool> _instanceExists(String templateId, DateTime start) async {
    final query = db.select(db.tasks)
      ..where((t) => t.parentRecurringId.equals(templateId))
      ..where(
        (t) =>
            t.occurrenceSlot.equals(start) |
            (t.occurrenceSlot.isNull() & t.scheduledStart.equals(start)),
      );
    final rows = await query.get();
    return rows.isNotEmpty;
  }

  TasksCompanion _instanceOf(Task template, DateTime start) {
    final now = DateTime.now();
    return TasksCompanion.insert(
      id: _newId(),
      title: template.title,
      notes: Value(template.notes),
      areaId: Value(template.areaId),
      status: const Value(TaskStatus.created),
      scheduledStart: Value(start),
      durationMin: Value(template.durationMin),
      dueDate: Value(start),
      // An occurrence is only as committed as its rule: a released habit
      // generates released dates that count, a draft one generates draft dates
      // that don't. Never the column default.
      publicationState: Value(template.publicationState),
      // The instance itself does not repeat; only the template carries rrule.
      parentRecurringId: Value(template.id),
      // Its permanent identity in the series. scheduledStart may move later;
      // this must not, or the slot looks empty and gets regenerated.
      occurrenceSlot: Value(start),
      meetingLink: Value(template.meetingLink),
      meetingProvider: Value(template.meetingProvider),
      locationName: Value(template.locationName),
      lat: Value(template.lat),
      lng: Value(template.lng),
      geofenceEnabled: Value(template.geofenceEnabled),
      reminderOffsets: Value(template.reminderOffsets),
      source: Value(template.source),
      priority: Value(template.priority),
      createdAt: now,
      updatedAt: now,
    );
  }
}

int _counter = 0;
String _fallbackId() =>
    'inst-${DateTime.now().microsecondsSinceEpoch}-${_counter++}';
