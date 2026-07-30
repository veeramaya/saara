import 'package:flutter/material.dart';

import '../../domain/enums.dart';

/// §4 One place that turns a task's disposition into a glyph, so every list —
/// Today, All tasks, Areas, Calendar — flags status the same way and can never
/// drift apart again. A rejected, missed or past-due task must never read the
/// same as one still ahead.

const _openStatuses = {
  TaskStatus.created,
  TaskStatus.started,
  TaskStatus.inProgress,
};

bool _isPastDue(TaskStatus status, DateTime? due) =>
    _openStatuses.contains(status) &&
    due != null &&
    due.isBefore(DateTime.now());

/// The leading glyph (icon + colour) for a task's status. [due] lets an open
/// task whose moment has passed read as "not answered" instead of pending.
({IconData icon, Color color}) taskStatusVisual(
  TaskStatus status,
  DateTime? due,
  ColorScheme scheme,
) {
  switch (status) {
    case TaskStatus.completed:
      return (icon: Icons.check_circle, color: Colors.green);
    case TaskStatus.rejected:
      // Declined / external — excluded from the score, so it reads neutral.
      return (icon: Icons.do_not_disturb_on, color: scheme.onSurfaceVariant);
    case TaskStatus.cancelled:
      // Backed out of your own word — a broken word, so it reads as such.
      return (icon: Icons.cancel, color: scheme.error);
    case TaskStatus.missed:
      return (icon: Icons.error, color: scheme.error);
    default:
      return _isPastDue(status, due)
          ? (icon: Icons.error_outline, color: scheme.error)
          : (icon: Icons.circle_outlined, color: scheme.outline);
  }
}

/// Completed, rejected and cancelled are all closed outcomes — strike titles.
bool taskStatusClosed(TaskStatus status) =>
    status == TaskStatus.completed ||
    status == TaskStatus.rejected ||
    status == TaskStatus.cancelled;

/// A commitment whose moment passed with no answer reads as red — it's a live
/// gap, not a neutral state.
bool taskStatusIsAlert(TaskStatus status, DateTime? due) =>
    status == TaskStatus.missed || _isPastDue(status, due);

/// The short status word to show beside a task — "not answered" for a past-due
/// open one, otherwise the status name.
String taskStatusLabel(TaskStatus status, DateTime? due) =>
    _isPastDue(status, due) ? 'not answered' : status.name;

/// A ready-made leading icon widget for the common list case.
class TaskStatusIcon extends StatelessWidget {
  const TaskStatusIcon({super.key, required this.status, this.due, this.size});
  final TaskStatus status;
  final DateTime? due;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final v = taskStatusVisual(status, due, Theme.of(context).colorScheme);
    return Icon(v.icon, color: v.color, size: size);
  }
}
