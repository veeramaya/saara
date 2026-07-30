import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/database.dart';
import '../../../domain/enums.dart';
import '../../../providers.dart';
import '../../common/task_status_icon.dart';
import '../../task_detail/task_detail_screen.dart';

/// §20.1 task card in the Home timeline. One-tap complete; long-press for other
/// dispositions. All status changes flow through [TaskService] → the state
/// machine → the ledger (§4).
class TaskTile extends ConsumerWidget {
  const TaskTile({super.key, required this.task, required this.day});

  final Task task;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final time = task.scheduledStart ?? task.dueDate;
    final done = task.status == TaskStatus.completed;
    final statusV = taskStatusVisual(task.status, time, scheme);
    final actionItems = task.kind == TaskKind.event
        ? (ref.watch(childTaskCountsProvider).valueOrNull ??
                  const {})[task.id] ??
              0
        : 0;

    return Card(
      child: ListTile(
        leading: IconButton(
          icon: Icon(statusV.icon),
          color: statusV.color,
          tooltip: done ? 'Completed' : 'Mark done',
          onPressed: done ? null : () => _complete(context, ref),
        ),
        title: Text(
          task.title,
          style: taskStatusClosed(task.status)
              ? TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: scheme.onSurfaceVariant,
                )
              : null,
        ),
        subtitle: Row(
          children: [
            // §4.1a a draft isn't a commitment yet — it shows, but it doesn't
            // count, and that difference should be visible rather than hidden
            // in a detail screen.
            if (task.publicationState == PublicationState.draft) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outline),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'DRAFT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (time != null) ...[
              const Icon(Icons.schedule, size: 14),
              const SizedBox(width: 4),
              Text(DateFormat.jm().format(time)),
              const SizedBox(width: 12),
            ],
            if (task.meetingLink != null) ...[
              const Icon(Icons.videocam_outlined, size: 14),
              const SizedBox(width: 4),
              Text(task.meetingProvider?.name ?? 'meeting'),
              const SizedBox(width: 12),
            ],
            if (actionItems > 0) ...[
              Icon(Icons.checklist, size: 14, color: scheme.primary),
              const SizedBox(width: 4),
              Text(
                '$actionItems action item${actionItems == 1 ? '' : 's'}',
                style: TextStyle(color: scheme.primary),
              ),
            ],
          ],
        ),
        trailing:
            (task.status == TaskStatus.started ||
                task.status == TaskStatus.inProgress)
            ? _TileTimer(task: task)
            : _StatusChip(status: task.status, due: time),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
        ),
        onLongPress: () => _disposition(context, ref),
      ),
    );
  }

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(taskServiceProvider).complete(task);
    ref.invalidate(tasksForDayProvider(day));
    ref.invalidate(tasksBetweenProvider); // calendar views
    ref.invalidate(taskTransitionsProvider(task.id));
    // One tap completes, so one tap must undo it (§4). Reopening is recorded,
    // not erased — the ledger stays honest either way.
    messenger.showSnackBar(
      SnackBar(
        content: Text('Completed “${task.title}”'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            final fresh = await ref.read(taskDaoProvider).findById(task.id);
            if (fresh == null) return;
            await ref.read(taskServiceProvider).reopen(fresh);
            ref.invalidate(tasksForDayProvider(day));
            ref.invalidate(tasksBetweenProvider); // calendar views
            ref.invalidate(taskTransitionsProvider(task.id));
            ref.invalidate(allTasksProvider);
            ref.invalidate(unscheduledTasksProvider);
          },
        ),
      ),
    );
  }

  Future<void> _disposition(BuildContext context, WidgetRef ref) async {
    final service = ref.read(taskServiceProvider);
    final scheme = Theme.of(context).colorScheme;
    // Only an event or a received invitation can fall away by the *other* side's
    // hand — an external cancellation, excluded from your score. A plain task you
    // own can be kept, moved, or broken — never externally cancelled (§4).
    final external =
        task.kind == TaskKind.event ||
        task.source == TaskSource.gcalSync ||
        task.source == TaskSource.shareTarget;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Start'),
              onTap: () => Navigator.pop(context, 'start'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Complete'),
              onTap: () => Navigator.pop(context, 'complete'),
            ),
            ListTile(
              leading: const Icon(Icons.event_repeat),
              title: const Text('Reschedule'),
              subtitle: const Text(
                'Move it and re-commit — not counted either way',
              ),
              onTap: () => Navigator.pop(context, 'reschedule'),
            ),
            ListTile(
              leading: Icon(Icons.cancel_outlined, color: scheme.error),
              title: const Text("Cancel — I'm not doing it"),
              subtitle: const Text('Your word, broken — counts against you'),
              onTap: () => Navigator.pop(context, 'cancel'),
            ),
            if (external)
              ListTile(
                leading: const Icon(Icons.event_busy_outlined),
                title: const Text('No longer happening'),
                subtitle: const Text(
                  'Cancelled by the other side — not counted',
                ),
                onTap: () => Navigator.pop(context, 'external'),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    switch (choice) {
      case 'start':
        await service.start(task);
      case 'complete':
        await service.complete(task);
      case 'reschedule':
        if (!context.mounted) return;
        final newStart = await _pickReschedule(context);
        if (newStart == null) return;
        await service.reschedule(task, newStart);
      case 'cancel':
        await service.cancel(task);
      case 'external':
        await service.reject(task, reason: 'no longer happening (external)');
    }
    ref.invalidate(tasksForDayProvider(day));
    ref.invalidate(tasksBetweenProvider); // calendar views
    ref.invalidate(taskTransitionsProvider(task.id));
    ref.invalidate(allTasksProvider);
    ref.invalidate(unscheduledTasksProvider);
    ref.invalidate(areaScoresProvider);
    ref.invalidate(reportSummaryProvider);
  }

  Future<DateTime?> _pickReschedule(BuildContext context) async {
    final now = DateTime.now();
    final base = task.scheduledStart ?? task.dueDate ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: base.isBefore(now) ? now : base,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 3)),
      helpText: 'Reschedule to',
    );
    if (date == null || !context.mounted) return null;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    return DateTime(
      date.year,
      date.month,
      date.day,
      t?.hour ?? base.hour,
      t?.minute ?? base.minute,
    );
  }
}

/// §4 glanceable live timer pill for an in-progress tile — counts up from the
/// first `started` transition (survives restarts), and turns red once past the
/// planned duration so you can wrap up and move on without opening the task.
class _TileTimer extends ConsumerStatefulWidget {
  const _TileTimer({required this.task});
  final Task task;

  @override
  ConsumerState<_TileTimer> createState() => _TileTimerState();
}

class _TileTimerState extends ConsumerState<_TileTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    d = d.abs();
    String two(int n) => n.toString().padLeft(2, '0');
    return d.inHours > 0
        ? '${d.inHours}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}'
        : '${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final transitions =
        ref.watch(taskTransitionsProvider(widget.task.id)).valueOrNull ??
        const <TaskTransition>[];
    // Latest start (see the detail timer) so a reopened task restarts its clock.
    DateTime? startedAt;
    for (final t in transitions) {
      if (t.toStatus == TaskStatus.started &&
          (startedAt == null || t.at.isAfter(startedAt))) {
        startedAt = t.at;
      }
    }
    if (startedAt == null) {
      return _StatusChip(
        status: widget.task.status,
        due: widget.task.scheduledStart ?? widget.task.dueDate,
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final elapsed = DateTime.now().difference(startedAt);
    final dur = widget.task.durationMin;
    final over = dur != null && elapsed > Duration(minutes: dur);
    final accent = over ? scheme.error : scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            over ? Icons.alarm : Icons.timer_outlined,
            size: 14,
            color: accent,
          ),
          const SizedBox(width: 4),
          Text(
            _fmt(elapsed),
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, this.due});
  final TaskStatus status;

  /// When this was meant to happen, so a commitment whose moment has passed
  /// doesn't read the same as one still ahead (see `_StatusLine`). Saara still
  /// never marks it missed on its own — that needs you to see it (§4).
  final DateTime? due;

  bool get _pastDue {
    const open = {
      TaskStatus.created,
      TaskStatus.started,
      TaskStatus.inProgress,
    };
    return open.contains(status) &&
        due != null &&
        due!.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_pastDue) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 14, color: scheme.error),
          const SizedBox(width: 4),
          Text(
            'not answered',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.error),
          ),
        ],
      );
    }
    return Text(status.name, style: Theme.of(context).textTheme.labelSmall);
  }
}
