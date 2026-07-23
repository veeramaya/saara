import 'package:drift/drift.dart' show Value;

import '../data/daos/task_dao.dart';
import '../data/database.dart';
import 'enums.dart';
import 'task_state_machine.dart';

/// Applies [TaskStateMachine] outcomes to the database (§4). Keeps the machine
/// pure while owning the small amount of I/O each transition needs — e.g.
/// reading the ledger for the first `started` time when completing a task.
class TaskService {
  TaskService({required this.dao, required this.machine});

  final TaskDao dao;
  final TaskStateMachine machine;

  Future<void> start(Task task, {String? note}) =>
      _apply(task, TaskStatus.started, note: note);

  Future<void> beginWork(Task task, {String? note}) =>
      _apply(task, TaskStatus.inProgress, note: note);

  /// §4 undo an accidental completion (or a wrongly-missed item): back to
  /// `started`. Recorded in the ledger — the completion isn't erased, so the
  /// integrity history stays truthful and the score follows current state.
  Future<void> reopen(Task task, {String? note}) =>
      _apply(task, TaskStatus.started, note: note ?? 'reopened');

  Future<void> reject(Task task, {String? reason}) =>
      _apply(task, TaskStatus.rejected, note: reason);

  /// §4: only call from the evening review / morning brief with the user seeing
  /// it — `finalizedInReview` guards against silent auto-missing.
  Future<void> markMissed(Task task, {String? note}) =>
      _apply(task, TaskStatus.missed, note: note, finalizedInReview: true);

  Future<void> reschedule(Task task, DateTime newStart, {String? note}) =>
      _apply(
        task,
        TaskStatus.rescheduled,
        newScheduledStart: newStart,
        note: note,
      );

  /// Completes a task, computing elapsed time from the first `started`
  /// transition in the ledger (§3.3, §4).
  Future<void> complete(Task task, {String? note}) async {
    final startedAt = await _firstStartedAt(task.id);
    final outcome = machine.transition(
      task,
      TaskStatus.completed,
      note: note,
      startedAt: startedAt,
    );
    await dao.applyTransition(
      updated: outcome.updatedTask,
      transition: await _stamp(outcome.transition, task),
    );
  }

  // ---- the ledger (§3.3, docs/LEDGER_DESIGN.md) ---------------------------

  String? _deviceIdCache;
  Future<String> _deviceId() async =>
      _deviceIdCache ??= await dao.attachedDatabase.deviceId();

  /// Adds the facts that make an entry readable on its own: the area and title
  /// **as they are now**, and which device saw it.
  ///
  /// Stamped here rather than in the state machine, which is pure and has no
  /// database to ask. Without this an entry is only a pointer, and reading
  /// another device's ledger would require its `tasks` table too.
  Future<TaskTransitionsCompanion> _stamp(
    TaskTransitionsCompanion row,
    Task task,
  ) async => row.copyWith(
    areaId: Value(task.areaId),
    titleSnapshot: Value(task.title),
    deviceId: Value(await _deviceId()),
  );

  Future<void> _record(
    Task task, {
    required LedgerEventKind kind,
    String? fromAreaId,
    String? areaId,
    String? reason,
  }) async {
    var row = TaskTransitionsCompanion.insert(
      id: machine.newId(),
      taskId: task.id,
      kind: Value(kind),
      // The lifecycle didn't move; record the status still standing.
      toStatus: task.status,
      at: machine.now(),
      reason: Value(reason),
    );
    row = await _stamp(row, task);
    if (fromAreaId != null) row = row.copyWith(fromAreaId: Value(fromAreaId));
    if (areaId != null) row = row.copyWith(areaId: Value(areaId));
    await dao.recordLedgerEntry(row);
  }

  /// The one way to bring a task into being.
  ///
  /// Every creation path — the card, Saara chat, voice, capture, import, a
  /// duplicate — goes through here, so no task can exist without a `created`
  /// entry in the ledger, and (when committed) a `released` one. Before this,
  /// each path inserted its own row and most wrote nothing to the ledger, so
  /// History was complete only for card-made tasks and publication state drifted
  /// to whatever the column default happened to be.
  ///
  /// [release] defaults to true: adding a task is committing to it. Pass false
  /// for the deliberate draft, or for a review queue (capture, bulk import)
  /// whose items are not commitments until the user says so.
  Future<Task> create(TasksCompanion companion, {bool release = true}) async {
    var withState = companion.copyWith(
      publicationState: Value(
        release ? PublicationState.released : PublicationState.draft,
      ),
    );
    // A task given a **duration** is a time block, not a bare due-date, so it
    // belongs on Google Calendar (which keeps the clock time) rather than
    // Google Tasks (date-only). Classifying it as an event routes it there —
    // otherwise the time is stripped on push and the task returns to another
    // device at midnight UTC (05:30 IST). The caller's explicit kind wins.
    final alreadyEvent =
        withState.kind.present && withState.kind.value == TaskKind.event;
    final hasDuration =
        withState.durationMin.present && withState.durationMin.value != null;
    if (!alreadyEvent && hasDuration) {
      withState = withState.copyWith(kind: const Value(TaskKind.event));
    }
    await dao.insertTask(withState);
    final task = (await dao.findById(withState.id.value))!;
    await recordCreated(task);
    if (release) await this.release(task);
    return task;
  }

  /// Notes that a commitment came into existence — still a draft.
  Future<void> recordCreated(Task task) =>
      _record(task, kind: LedgerEventKind.created);

  /// **Giving your word.** Flips the task to released and records the moment,
  /// because when you committed is a fact in its own right (§4.1d) — the gap
  /// between committing and acting is worth being able to see.
  Future<void> release(Task task) async {
    await dao.setPublicationState(task.id, PublicationState.released);
    await _record(task, kind: LedgerEventKind.released);
  }

  /// Notes a removal. What it already accrued stays: delete removes the future,
  /// never the past (§4.2).
  Future<void> recordDeleted(Task task, {String? reason}) =>
      _record(task, kind: LedgerEventKind.deleted, reason: reason);

  /// Re-files a task, as an **adjusting entry** rather than an edit (§4.3).
  /// The original posting stands; reporting follows the correction.
  ///
  /// [reason] is optional and never required — it exists because noticing
  /// *"I keep filing entertainment under health"* is worth learning from, and
  /// for no other purpose. It is never scored.
  Future<void> correctArea(
    Task task,
    String? newAreaId, {
    String? reason,
  }) async {
    if (task.areaId == newAreaId) return;
    await dao.setArea(task.id, newAreaId);
    await _record(
      task,
      kind: LedgerEventKind.corrected,
      fromAreaId: task.areaId,
      areaId: newAreaId,
      reason: reason,
    );
  }

  Future<void> _apply(
    Task task,
    TaskStatus to, {
    String? note,
    DateTime? newScheduledStart,
    bool finalizedInReview = false,
  }) async {
    final outcome = machine.transition(
      task,
      to,
      note: note,
      newScheduledStart: newScheduledStart,
      finalizedInReview: finalizedInReview,
    );
    await dao.applyTransition(
      updated: outcome.updatedTask,
      transition: await _stamp(outcome.transition, task),
    );
    if (outcome.spawnedInstance != null) {
      await dao.insertTask(outcome.spawnedInstance!);
    }
  }

  Future<DateTime?> _firstStartedAt(String taskId) async {
    final transitions = await dao.transitionsFor(taskId);
    for (final t in transitions) {
      if (t.toStatus == TaskStatus.started) return t.at;
    }
    return null;
  }
}
