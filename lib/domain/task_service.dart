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
      transition: outcome.transition,
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
      transition: outcome.transition,
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
