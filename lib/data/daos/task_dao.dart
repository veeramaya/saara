import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import '../../domain/rrule_util.dart';
import '../database.dart';
import '../tables/task_relations.dart';
import '../tables/tasks.dart';

part 'task_dao.g.dart';

/// Data access for tasks and the integrity ledger (§3.3, §4).
///
/// All status changes should go through [TaskStateMachine]
/// (`domain/task_state_machine.dart`), which calls [applyTransition] so the
/// TaskTransition row and the Task mutation commit atomically.
@DriftAccessor(tables: [Tasks, TaskTransitions, TaskParticipants])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  /// Tasks scheduled/due on [day] (local date), excluding soft-deleted rows.
  /// Backs the Home timeline (§7.1) and morning/evening flows (§7.3, §7.4).
  Future<List<Task>> tasksForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(tasks)
          ..where((t) => t.deletedAt.isNull())
          // Exclude recurring templates (rrule set, no parent) — only their
          // generated instances and one-off tasks appear on the timeline (§4).
          ..where((t) => t.rrule.isNull() | t.parentRecurringId.isNotNull())
          ..where(
            (t) =>
                (t.scheduledStart.isBiggerOrEqualValue(start) &
                    t.scheduledStart.isSmallerThanValue(end)) |
                (t.dueDate.isBiggerOrEqualValue(start) &
                    t.dueDate.isSmallerThanValue(end)),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledStart)]))
        .get();
  }

  /// Tasks whose scheduled/due time falls in [from, to) — backs the calendar
  /// view (month/week/range). Excludes soft-deleted rows and recurring
  /// templates (only instances/one-offs are shown).
  Future<List<Task>> tasksBetween(DateTime from, DateTime to) {
    return (select(tasks)
          ..where((t) => t.deletedAt.isNull())
          ..where((t) => t.rrule.isNull() | t.parentRecurringId.isNotNull())
          ..where(
            (t) =>
                (t.scheduledStart.isBiggerOrEqualValue(from) &
                    t.scheduledStart.isSmallerThanValue(to)) |
                (t.dueDate.isBiggerOrEqualValue(from) &
                    t.dueDate.isSmallerThanValue(to)),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledStart)]))
        .get();
  }

  /// Open items carried from before [day] that still demand a disposition
  /// (§4, §7.3 — "yesterday's open items", no silent carryover).
  Future<List<Task>> openItemsBefore(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    const openStatuses = [
      TaskStatus.created,
      TaskStatus.started,
      TaskStatus.inProgress,
    ];
    return (select(tasks)
          ..where((t) => t.deletedAt.isNull())
          ..where((t) => t.status.isInValues(openStatuses))
          ..where(
            (t) =>
                t.dueDate.isSmallerThanValue(start) |
                t.scheduledStart.isSmallerThanValue(start),
          ))
        .get();
  }

  Future<Task?> findById(String id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Non-deleted tasks assigned to [areaId] (§7.5 area task list). Recurring
  /// templates are excluded — only concrete instances/one-offs are actionable.
  Future<List<Task>> tasksForArea(String areaId) {
    return (select(tasks)
          ..where((t) => t.deletedAt.isNull())
          ..where((t) => t.areaId.equals(areaId))
          ..where((t) => t.rrule.isNull() | t.parentRecurringId.isNotNull())
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.scheduledStart,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  /// Action items hung under an event (§4) — a meeting's child tasks, oldest
  /// first so the list reads in the order they were captured.
  Future<List<Task>> childTasksForEvent(String eventId) {
    return (select(tasks)
          ..where((t) => t.deletedAt.isNull())
          ..where((t) => t.parentEventId.equals(eventId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  /// Recurring templates: rrule set, no parent, not deleted (§4). The
  /// RecurringEngine expands these into dated instances.
  Future<List<Task>> recurringTemplates() {
    return (select(tasks)
          ..where((t) => t.deletedAt.isNull())
          ..where((t) => t.rrule.isNotNull() & t.parentRecurringId.isNull()))
        .get();
  }

  /// Live (not-yet-deleted) instances generated from a recurring template.
  Future<List<Task>> instancesOfTemplate(String templateId) {
    return (select(tasks)
          ..where((t) => t.deletedAt.isNull())
          ..where((t) => t.parentRecurringId.equals(templateId)))
        .get();
  }

  /// Soft-deletes a task and, when it is a recurring template, every instance
  /// it generated. Deleting the template alone only stops *future* expansion —
  /// the occurrences already written stay on the calendar, which reads to the
  /// user as "delete didn't work" (§4).
  Future<int> softDeleteCascade(String taskId, {bool instances = true}) async {
    final now = DateTime.now();
    final stamp = TasksCompanion(deletedAt: Value(now), updatedAt: Value(now));
    var n = await (update(
      tasks,
    )..where((t) => t.id.equals(taskId))).write(stamp);
    if (instances) {
      n +=
          await (update(tasks)
                ..where((t) => t.deletedAt.isNull())
                ..where((t) => t.parentRecurringId.equals(taskId)))
              .write(stamp);
    }
    return n;
  }

  /// Outlook/Google "This and following events": soft-delete this occurrence
  /// and every later one, and stop the series generating new dates — while
  /// keeping the occurrences *before* [from]. Deleting the template halts future
  /// expansion; already-materialised past instances are untouched.
  Future<int> softDeleteThisAndFollowing(
    String templateId,
    DateTime from,
  ) async {
    final now = DateTime.now();
    final stamp = TasksCompanion(deletedAt: Value(now), updatedAt: Value(now));
    // Stop future generation by removing the template itself.
    var n = await (update(
      tasks,
    )..where((t) => t.id.equals(templateId))).write(stamp);
    // Delete this occurrence and all later ones; keep earlier dates.
    n +=
        await (update(tasks)
              ..where((t) => t.deletedAt.isNull())
              ..where((t) => t.parentRecurringId.equals(templateId))
              ..where((t) => t.scheduledStart.isBiggerOrEqualValue(from)))
            .write(stamp);
    return n;
  }

  /// Ledger entries whose moment falls in [from, to) — the input to reporting
  /// (§4). Deliberately does **not** join to `tasks`: an entry is self-contained
  /// and a disposition that happened must still count once the task is gone.
  Future<List<TaskTransition>> ledgerEntriesBetween(
    DateTime from,
    DateTime to,
  ) {
    return (select(taskTransitions)
          ..where((t) => t.at.isBiggerOrEqualValue(from))
          ..where((t) => t.at.isSmallerThanValue(to))
          ..orderBy([(t) => OrderingTerm(expression: t.at)]))
        .get();
  }

  /// Ids of tasks that carry a released commitment.
  ///
  /// Used as the fallback for entries recorded before the draft/released
  /// distinction existed, which have no `released` entry to anchor them. Where
  /// a `released` entry *does* exist the ledger wins, so passing every released
  /// id is safe.
  Future<Set<String>> releasedTaskIds() async {
    final rows =
        await (selectOnly(tasks)
              ..addColumns([tasks.id])
              ..where(
                tasks.publicationState.equalsValue(PublicationState.released),
              ))
            .get();
    return {for (final r in rows) r.read(tasks.id)!};
  }

  /// Released commitments whose moment has passed with **no answer** — neither
  /// kept nor broken, because they were never dispositioned.
  ///
  /// Deliberately *not* folded into the score. Saara does not decide on your
  /// behalf that silence was a failure — but nor will it let silence be free:
  /// counted this way, ignoring a commitment shows up, while still leaving the
  /// judgement to you (§4.1).
  ///
  /// Drafts are excluded — nothing was promised, so nothing is owed.
  Future<Map<String?, int>> unansweredByArea(DateTime asOf) async {
    const open = [
      TaskStatus.created,
      TaskStatus.started,
      TaskStatus.inProgress,
    ];
    final rows =
        await (select(tasks)
              ..where((t) => t.deletedAt.isNull())
              ..where(
                (t) =>
                    t.publicationState.equalsValue(PublicationState.released),
              )
              // Rules themselves never come due; their occurrences do.
              ..where((t) => t.rrule.isNull() | t.parentRecurringId.isNotNull())
              ..where((t) => t.status.isInValues(open))
              ..where(
                (t) =>
                    t.scheduledStart.isSmallerThanValue(asOf) |
                    t.dueDate.isSmallerThanValue(asOf),
              ))
            .get();

    final out = <String?, int>{};
    for (final t in rows) {
      out[t.areaId] = (out[t.areaId] ?? 0) + 1;
    }
    return out;
  }

  Future<List<TaskTransition>> transitionsFor(String taskId) =>
      (select(taskTransitions)
            ..where((t) => t.taskId.equals(taskId))
            ..orderBy([(t) => OrderingTerm(expression: t.at)]))
          .get();

  Future<void> insertTask(TasksCompanion task) => into(tasks).insert(task);

  /// §3.3 TaskParticipant — on-device contact refs only (never uploaded, §1.4).
  Future<List<TaskParticipant>> participantsForTask(String taskId) =>
      (select(taskParticipants)..where((p) => p.taskId.equals(taskId))).get();

  Future<void> addParticipant(TaskParticipantsCompanion participant) =>
      into(taskParticipants).insert(participant);

  // ---- Google Tasks sync (§9) ---------------------------------------------
  // The Google Task id is stored in `gcal_event_id`, its list in
  // `gcal_calendar_id` (reusing the sync columns for the Tasks integration).

  /// Google Task ids already imported/pushed — for idempotent import.
  Future<Set<String>> syncedGoogleTaskIds() async {
    final rows =
        await (selectOnly(tasks)
              ..addColumns([tasks.gcalEventId])
              ..where(tasks.gcalEventId.isNotNull()))
            .get();
    return {
      for (final r in rows)
        if (r.read(tasks.gcalEventId) != null) r.read(tasks.gcalEventId)!,
    };
  }

  /// Open, one-off, not-yet-pushed **tasks** to send to Google Tasks.
  /// A row is a to-do (not a calendar event) when kind is null (legacy) or task.
  ///
  /// **Recurring rows are excluded on purpose.** Pushing each materialised
  /// occurrence turned one daily habit into ~21 separate Google tasks, and each
  /// device expanded *and* pushed its own copies — which is how a handful of
  /// habits became 208 overlapping duplicates that no delete could line up
  /// across devices. The *rule* syncs once instead (see [eventsToPush]); every
  /// device expands its own occurrences locally and never pushes them.
  Future<List<Task>> tasksToPush() {
    const open = [
      TaskStatus.created,
      TaskStatus.started,
      TaskStatus.inProgress,
    ];
    return (select(tasks)
          ..where((t) => t.deletedAt.isNull())
          ..where((t) => t.gcalEventId.isNull())
          ..where((t) => t.kind.isNull() | t.kind.equalsValue(TaskKind.task))
          // one-off only: no rule of its own, and not generated from one
          ..where((t) => t.rrule.isNull() & t.parentRecurringId.isNull())
          // Drafts stay off Google (§4.1a). Google is where the outside world
          // sees your calendar; half-formed thinking posted there is public
          // before you meant it, and clutters a calendar others may share.
          ..where(
            (t) => t.publicationState.equalsValue(PublicationState.released),
          )
          ..where((t) => t.status.isInValues(open)))
        .get();
  }

  /// Every non-deleted, non-template task/event (all statuses) — backs the
  /// global Tasks list + search (§7). Newest scheduled first.
  Future<List<Task>> allTasks() {
    return (select(tasks)
          ..where((t) => t.deletedAt.isNull())
          ..where((t) => t.rrule.isNull() | t.parentRecurringId.isNotNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.scheduledStart),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .get();
  }

  /// Open tasks with no date at all. Every timeline query filters on a date, so
  /// without this a dateless task is saved but visible nowhere the user looks —
  /// indistinguishable from Save having failed (§7.1).
  Future<List<Task>> unscheduledTasks() {
    const open = [
      TaskStatus.created,
      TaskStatus.started,
      TaskStatus.inProgress,
    ];
    return (select(tasks)
          ..where((t) => t.deletedAt.isNull())
          ..where((t) => t.rrule.isNull() | t.parentRecurringId.isNotNull())
          ..where((t) => t.status.isInValues(open))
          ..where((t) => t.scheduledStart.isNull() & t.dueDate.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Soft-deleted tasks/events — the Trash (§7). Most-recently-deleted first.
  Future<List<Task>> deletedTasks() {
    return (select(tasks)
          ..where((t) => t.deletedAt.isNotNull())
          ..where((t) => t.rrule.isNull() | t.parentRecurringId.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]))
        .get();
  }

  /// Restore a soft-deleted task and unlink it from Google, so the next sync
  /// re-creates it (the Google copy was already deleted). §7.
  Future<void> restoreTask(String id) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        deletedAt: const Value(null),
        gcalEventId: const Value(null),
        gcalCalendarId: const Value(null),
        gcalEtag: const Value(null),
        lastSyncedAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// The per-date copies Saara itself pushed to Google for a repeating task —
  /// the output of the duplication bug (one daily habit became ~21 Google
  /// rows). Used by the one-off cleanup.
  ///
  /// **Safety:** rows imported *from* Google (`gcalSync` / `gcalEvent`) are
  /// excluded, so the user's own calendar entries can never be selected for
  /// deletion. Only rows Saara created and pushed are eligible. Soft-deleted
  /// rows are included — their Google copy may still be orphaned there.
  Future<List<Task>> saaraPushedOccurrences() {
    const imported = [TaskSource.gcalSync, TaskSource.gcalEvent];
    return (select(tasks)
          ..where((t) => t.gcalEventId.isNotNull())
          // a generated per-date copy, never a rule or a one-off
          ..where((t) => t.parentRecurringId.isNotNull())
          ..where((t) => t.source.isNotInValues(imported)))
        .get();
  }

  /// Outlook/Google **"All events"**: apply an edit to the rule and to every
  /// live occurrence.
  ///
  /// [shared] carries the fields that are the same on every date (title, notes,
  /// duration…). A time change is handled separately via [newHour]/[newMinute]:
  /// each occurrence keeps **its own date** and only the time-of-day moves.
  ///
  /// `occurrenceSlot` moves with `scheduledStart` here — deliberately. Once the
  /// rule's own start time changes, the next expansion generates slots at the
  /// new time; if the existing rows kept their old slots they would look
  /// un-generated and the engine would create a second copy of every date.
  Future<void> applyToWholeSeries({
    required String templateId,
    required TasksCompanion shared,
    int? newHour,
    int? newMinute,
  }) async {
    final now = DateTime.now();
    DateTime? shift(DateTime? d) => (d == null || newHour == null)
        ? d
        : DateTime(d.year, d.month, d.day, newHour, newMinute ?? 0);

    await transaction(() async {
      // The rule itself — its start time seeds every future expansion.
      final tpl = await findById(templateId);
      if (tpl != null) {
        await (update(tasks)..where((t) => t.id.equals(templateId))).write(
          shared.copyWith(
            scheduledStart: Value(shift(tpl.scheduledStart)),
            dueDate: Value(shift(tpl.dueDate)),
            updatedAt: Value(now),
          ),
        );
      }
      for (final o in await instancesOfTemplate(templateId)) {
        await (update(tasks)..where((t) => t.id.equals(o.id))).write(
          shared.copyWith(
            scheduledStart: Value(shift(o.scheduledStart)),
            dueDate: Value(shift(o.dueDate)),
            occurrenceSlot: Value(shift(o.occurrenceSlot ?? o.scheduledStart)),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  /// Outlook/Google **"This and following events"**: end the existing rule just
  /// before [fromSlot] and hand the rest of the series to a new rule.
  ///
  /// Splitting — rather than editing in place — is what keeps earlier dates
  /// untouched. Editing the one rule would change the past too, and leaving the
  /// old rule live would have it regenerate the dates the new rule now owns.
  ///
  /// Returns the id of the new rule, or null if the template is missing.
  Future<String?> splitSeriesAt({
    required String templateId,
    required DateTime fromSlot,
    required String newTemplateId,
    required TasksCompanion shared,
    required DateTime newStart,
  }) async {
    final tpl = await findById(templateId);
    if (tpl == null || tpl.rrule == null) return null;
    final now = DateTime.now();

    await transaction(() async {
      // 1. Cap the old rule a second before the split, so it keeps only the
      //    dates before this one and never generates past it again.
      await (update(tasks)..where((t) => t.id.equals(templateId))).write(
        TasksCompanion(
          rrule: Value(
            rruleWithUntil(
              tpl.rrule!,
              fromSlot.subtract(const Duration(seconds: 1)),
            ),
          ),
          updatedAt: Value(now),
        ),
      );
      // 2. Retire the occurrences from the split onward — the new rule owns
      //    those dates now.
      await (update(tasks)
            ..where((t) => t.deletedAt.isNull())
            ..where((t) => t.parentRecurringId.equals(templateId))
            ..where(
              (t) =>
                  t.occurrenceSlot.isBiggerOrEqualValue(fromSlot) |
                  (t.occurrenceSlot.isNull() &
                      t.scheduledStart.isBiggerOrEqualValue(fromSlot)),
            ))
          .write(TasksCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      // 3. The new rule carries the edit forward from this date.
      await into(tasks).insert(
        shared.copyWith(
          id: Value(newTemplateId),
          rrule: Value(tpl.rrule!.replaceAll(RegExp('UNTIL=[^;]*;?'), '')),
          parentRecurringId: const Value(null),
          occurrenceSlot: const Value(null),
          scheduledStart: Value(newStart),
          dueDate: Value(newStart),
          // A fresh rule is not yet on Google; it pushes as its own event.
          gcalEventId: const Value(null),
          gcalCalendarId: const Value(null),
          gcalEtag: const Value(null),
          lastSyncedAt: const Value(null),
          status: const Value(TaskStatus.created),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
    return newTemplateId;
  }

  /// Drops a row's Google link without deleting the row — after its remote copy
  /// is removed, the local occurrence stays as a purely local date (§9).
  Future<void> unlinkFromGoogle(String id) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      const TasksCompanion(
        gcalEventId: Value(null),
        gcalCalendarId: Value(null),
        gcalEtag: Value(null),
        lastSyncedAt: Value(null),
      ),
    );
  }

  /// Open, non-template tasks/events (not deleted) — candidates for a natural-
  /// language edit command ("move dentist to Friday"), §19.
  Future<List<Task>> openTasks() {
    const open = [
      TaskStatus.created,
      TaskStatus.started,
      TaskStatus.inProgress,
    ];
    return (select(tasks)
          ..where((t) => t.deletedAt.isNull())
          ..where((t) => t.rrule.isNull() | t.parentRecurringId.isNotNull())
          ..where((t) => t.status.isInValues(open)))
        .get();
  }

  /// A repeating *rule* — the row that owns the RRULE. These sync through
  /// Calendar (which speaks RRULE natively) rather than Tasks, so the rule
  /// travels once instead of one row per date.
  static Expression<bool> _isRecurringRule(Tasks t) =>
      t.rrule.isNotNull() & t.parentRecurringId.isNull();

  /// Tasks linked to a Google **Task** (any status, incl. soft-deleted) — the
  /// left side of the two-way Tasks reconcile. Excludes calendar events and
  /// recurring rules (the latter reconcile through Calendar, below).
  Future<List<Task>> linkedTasks() =>
      (select(tasks)
            ..where((t) => t.gcalEventId.isNotNull())
            ..where((t) => t.kind.isNull() | t.kind.equalsValue(TaskKind.task))
            ..where((t) => _isRecurringRule(t).not()))
          .get();

  /// New rows to create on Google **Calendar**: events, plus any repeating rule
  /// (whatever its kind). A rule goes out as ONE event carrying its RRULE —
  /// Google expands it, and each device expands its own copy locally, so no
  /// per-date rows are ever pushed (see [tasksToPush]).
  Future<List<Task>> eventsToPush() =>
      (select(tasks)
            ..where((t) => t.deletedAt.isNull())
            ..where((t) => t.gcalEventId.isNull())
            ..where((t) => t.scheduledStart.isNotNull())
            // Drafts stay off Google — see [tasksToPush].
            ..where(
              (t) => t.publicationState.equalsValue(PublicationState.released),
            )
            ..where(
              (t) => t.kind.equalsValue(TaskKind.event) | _isRecurringRule(t),
            ))
          .get();

  /// Rows already linked to a Google Calendar event — the left side of the
  /// two-way Calendar reconcile. Mirrors [eventsToPush]'s scope.
  Future<List<Task>> linkedEvents() =>
      (select(tasks)
            ..where((t) => t.gcalEventId.isNotNull())
            ..where(
              (t) => t.kind.equalsValue(TaskKind.event) | _isRecurringRule(t),
            ))
          .get();

  /// Records the Google id/list/updated-stamp after a push or import. Sets
  /// last_synced_at = updated_at = now so the task isn't seen as locally dirty
  /// on the next sync.
  Future<void> markSynced(
    String taskId, {
    required String googleId,
    required String listId,
    required String updated,
  }) {
    final now = DateTime.now();
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        gcalEventId: Value(googleId),
        gcalCalendarId: Value(listId),
        gcalEtag: Value(updated),
        lastSyncedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Applies a remote Google change onto a Saara task (last-writer-wins pick).
  Future<void> applyRemoteToTask(
    String taskId, {
    required String title,
    String? notes,
    DateTime? due,
    required bool completed,
    required String updated,
  }) {
    final now = DateTime.now();
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        title: Value(title),
        notes: Value(notes),
        dueDate: Value(due),
        scheduledStart: Value(due),
        status: Value(completed ? TaskStatus.completed : TaskStatus.created),
        completedAt: Value(completed ? now : null),
        gcalEtag: Value(updated),
        lastSyncedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Refreshes sync markers after pushing a local change to Google.
  Future<void> touchSynced(String taskId, String updated) {
    final now = DateTime.now();
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        gcalEtag: Value(updated),
        lastSyncedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Soft-deletes a task because it was deleted on Google.
  Future<void> softDeleteFromSync(String taskId) {
    final now = DateTime.now();
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        deletedAt: Value(now),
        lastSyncedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Appends a ledger row for a sync-driven status change (§3.3).
  Future<void> recordSyncTransition(TaskTransitionsCompanion transition) =>
      into(taskTransitions).insert(transition);

  /// All ledger transitions at or after [from], ordered — backs the reports
  /// dashboard (§13). Reports are computed from the ledger, never from mutable
  /// task state (§3.3).
  Future<List<TaskTransition>> transitionsSince(DateTime from) {
    return (select(taskTransitions)
          ..where((t) => t.at.isBiggerOrEqualValue(from))
          ..orderBy([(t) => OrderingTerm(expression: t.at)]))
        .get();
  }

  /// Atomically write the new task state and its ledger row (§3.3).
  Future<void> applyTransition({
    required Task updated,
    required TaskTransitionsCompanion transition,
  }) {
    return transaction(() async {
      await update(tasks).replace(updated);
      await into(taskTransitions).insert(transition);
    });
  }

  /// Appends one entry to the ledger.
  ///
  /// Append-only by design: there is no update or delete counterpart, and there
  /// must never be one. Ids are unique per entry, so re-running an import is
  /// harmless — `insertOnConflictUpdate` keeps a merge idempotent rather than
  /// throwing on an entry another device already sent us.
  Future<void> recordLedgerEntry(TaskTransitionsCompanion entry) =>
      into(taskTransitions).insertOnConflictUpdate(entry);

  /// Draft ⇄ released (§4.1a). Kept separate from the general update path so
  /// the moment of commitment always travels with a ledger entry beside it.
  Future<void> setPublicationState(String taskId, PublicationState state) {
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        publicationState: Value(state),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Re-files a task. Callers should use `TaskService.correctArea`, which also
  /// posts the adjusting entry — moving the area without recording it would let
  /// history be rewritten quietly, which is exactly what the ledger forbids.
  Future<void> setArea(String taskId, String? areaId) {
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(areaId: Value(areaId), updatedAt: Value(DateTime.now())),
    );
  }
}
