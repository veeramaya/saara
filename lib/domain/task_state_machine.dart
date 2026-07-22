import 'package:drift/drift.dart' show Value;

import '../data/database.dart';
import 'enums.dart';

/// Thrown when a caller attempts a status change the machine (§4) forbids.
class InvalidTransitionException implements Exception {
  InvalidTransitionException(this.from, this.to, [this.reason]);
  final TaskStatus from;
  final TaskStatus? to;
  final String? reason;

  @override
  String toString() =>
      'InvalidTransitionException(${from.name} → ${to?.name}'
      '${reason == null ? '' : ': $reason'})';
}

/// The result of a legal transition: the mutated task, its ledger row, and —
/// for a reschedule — the fresh instance to insert (§4).
class TransitionOutcome {
  TransitionOutcome({
    required this.updatedTask,
    required this.transition,
    this.spawnedInstance,
  });

  /// The existing task with its new status and any side-effect fields set.
  final Task updatedTask;

  /// The integrity-ledger row to append (§3.3). Never skipped.
  final TaskTransitionsCompanion transition;

  /// For `rescheduled`: the new task instance to insert, linked back through
  /// [transition]'s note (§4). Null for every other transition.
  final TasksCompanion? spawnedInstance;
}

/// Task state machine (§4). Pure and deterministic — it computes the outcome of
/// a status change but performs no I/O. Persist the outcome atomically via
/// `TaskDao.applyTransition` so the task mutation and its ledger row commit
/// together (§3.3: "reports are computed from [the ledger], never from mutable
/// state alone").
///
/// Rules encoded here (§4):
/// - `missed` is only reachable when [finalizedInReview] is true — the evening
///   review or day rollover *presents* it. No silent auto-missing.
/// - `rejected` accepts an optional one-line [note] (reason).
/// - `rescheduled` closes the current instance and spawns a new one at
///   [newScheduledStart]; the chain is traceable through the transition note.
/// - `completed` stamps `completed_at` and computes `time_to_complete_min` from
///   the first `started` transition (passed as [startedAt]).
/// - Terminal states (`completed`, `missed`, `rejected`, `rescheduled`) have no
///   forward transitions; past edits go through a separate "amend log" flow.
class TaskStateMachine {
  TaskStateMachine({DateTime Function()? clock, String Function()? idGenerator})
    : _now = clock ?? DateTime.now,
      _newId = idGenerator ?? _uuidFallback;

  final DateTime Function() _now;
  final String Function() _newId;

  /// A fresh ledger-entry id. Exposed so callers that record entries the machine
  /// has no opinion about — creation, release, deletion, correction — mint ids
  /// the same way and stay collision-free across devices.
  String newId() => _newId();

  /// The clock every ledger entry is stamped from.
  ///
  /// Shared deliberately: entry times decide what counted as a draft and what
  /// came after you gave your word, so they must all come from one source. Two
  /// clocks would let a release land on the same instant as work recorded
  /// before it, and the boundary would stop meaning anything.
  DateTime now() => _now();

  /// Legal forward transitions. Terminal states map to an empty set.
  static const Map<TaskStatus, Set<TaskStatus>> _allowed = {
    TaskStatus.created: {
      TaskStatus.started,
      TaskStatus.completed, // quick check-off shortcut
      TaskStatus.missed,
      TaskStatus.rejected,
      TaskStatus.rescheduled,
    },
    TaskStatus.started: {
      TaskStatus.inProgress,
      TaskStatus.completed,
      TaskStatus.missed,
      TaskStatus.rejected,
      TaskStatus.rescheduled,
    },
    TaskStatus.inProgress: {
      TaskStatus.completed,
      TaskStatus.missed,
      TaskStatus.rejected,
      TaskStatus.rescheduled,
    },
    // §4 completion is reversible — an accidental check-off (one tap on a tile)
    // must not be a one-way door. Reopening is *recorded* as a transition, so
    // the ledger stays honest and the score simply follows current state; the
    // completion is never silently erased.
    TaskStatus.completed: {TaskStatus.started},
    TaskStatus.missed: {TaskStatus.started},
    TaskStatus.rejected: {},
    TaskStatus.rescheduled: {},
  };

  bool canTransition(TaskStatus from, TaskStatus to) =>
      _allowed[from]?.contains(to) ?? false;

  /// Compute the outcome of moving [task] to [to]. Throws
  /// [InvalidTransitionException] if the move is illegal or a rule is violated.
  TransitionOutcome transition(
    Task task,
    TaskStatus to, {
    String? note,
    DateTime? newScheduledStart,
    DateTime? startedAt,
    bool finalizedInReview = false,
  }) {
    final from = task.status;
    if (!canTransition(from, to)) {
      throw InvalidTransitionException(
        from,
        to,
        _allowed[from]!.isEmpty ? 'task is in a terminal state' : 'not allowed',
      );
    }

    final at = _now();

    switch (to) {
      case TaskStatus.missed:
        if (!finalizedInReview) {
          // §4: never silently auto-miss; must be presented to the user.
          throw InvalidTransitionException(
            from,
            to,
            'missed may only be finalized in the evening review or morning '
            'brief (§4)',
          );
        }
        return _simple(task, to, at, note);

      case TaskStatus.rescheduled:
        if (newScheduledStart == null) {
          throw InvalidTransitionException(
            from,
            to,
            'rescheduled requires a newScheduledStart',
          );
        }
        return _reschedule(task, at, newScheduledStart, note);

      case TaskStatus.completed:
        final elapsed = startedAt == null
            ? null
            : at.difference(startedAt).inMinutes;
        final updated = task.copyWith(
          status: TaskStatus.completed,
          completedAt: Value(at),
          timeToCompleteMin: Value(elapsed),
          updatedAt: at,
        );
        return TransitionOutcome(
          updatedTask: updated,
          transition: _row(task.id, from, to, at, note),
        );

      case TaskStatus.started:
        // Reopening a completed/missed task clears the completion stamps so a
        // later completion recomputes cleanly. The ledger keeps both rows, so
        // the history still shows it was completed and then reopened.
        if (from == TaskStatus.completed || from == TaskStatus.missed) {
          final reopened = task.copyWith(
            status: TaskStatus.started,
            completedAt: const Value(null),
            timeToCompleteMin: const Value(null),
            updatedAt: at,
          );
          return TransitionOutcome(
            updatedTask: reopened,
            transition: _row(task.id, from, to, at, note ?? 'reopened'),
          );
        }
        return _simple(task, to, at, note);

      case TaskStatus.rejected:
      case TaskStatus.inProgress:
      case TaskStatus.created:
        return _simple(task, to, at, note);
    }
  }

  TransitionOutcome _simple(
    Task task,
    TaskStatus to,
    DateTime at,
    String? note,
  ) {
    return TransitionOutcome(
      updatedTask: task.copyWith(status: to, updatedAt: at),
      transition: _row(task.id, task.status, to, at, note),
    );
  }

  TransitionOutcome _reschedule(
    Task task,
    DateTime at,
    DateTime newScheduledStart,
    String? note,
  ) {
    final newId = _newId();
    final linkNote =
        'rescheduled → $newId'
        '${note == null || note.isEmpty ? '' : ' ($note)'}';

    // Close the current instance.
    final closed = task.copyWith(status: TaskStatus.rescheduled, updatedAt: at);

    // Spawn a fresh, open instance at the new time, carrying the task's shape.
    final spawn = TasksCompanion.insert(
      id: newId,
      title: task.title,
      notes: Value(task.notes),
      areaId: Value(task.areaId),
      status: Value(TaskStatus.created),
      scheduledStart: Value(newScheduledStart),
      durationMin: Value(task.durationMin),
      dueDate: Value(task.dueDate),
      rrule: Value(task.rrule),
      parentRecurringId: Value(task.parentRecurringId),
      meetingLink: Value(task.meetingLink),
      meetingProvider: Value(task.meetingProvider),
      locationName: Value(task.locationName),
      lat: Value(task.lat),
      lng: Value(task.lng),
      geofenceEnabled: Value(task.geofenceEnabled),
      reminderOffsets: Value(task.reminderOffsets),
      source: Value(task.source),
      priority: Value(task.priority),
      createdAt: at,
      updatedAt: at,
    );

    return TransitionOutcome(
      updatedTask: closed,
      transition: _row(
        task.id,
        task.status,
        TaskStatus.rescheduled,
        at,
        linkNote,
      ),
      spawnedInstance: spawn,
    );
  }

  TaskTransitionsCompanion _row(
    String taskId,
    TaskStatus from,
    TaskStatus to,
    DateTime at,
    String? note,
  ) {
    return TaskTransitionsCompanion.insert(
      id: _newId(),
      taskId: taskId,
      fromStatus: Value(from),
      toStatus: to,
      at: at,
      note: Value(note),
    );
  }
}

// Minimal fallback id generator so the machine is usable without wiring a uuid
// package in tests. Production code injects a real uuid v4 generator (see
// providers.dart). Not cryptographically strong — do not use for secrets.
int _counter = 0;
String _uuidFallback() =>
    'gen-${DateTime.now().microsecondsSinceEpoch}-${_counter++}';
