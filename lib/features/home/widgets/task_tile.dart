import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/database.dart';
import '../../../domain/enums.dart';
import '../../../providers.dart';
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
    final actionItems = task.kind == TaskKind.event
        ? (ref.watch(childTaskCountsProvider).valueOrNull ??
                  const {})[task.id] ??
              0
        : 0;

    return Card(
      child: ListTile(
        leading: IconButton(
          icon: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked),
          color: done ? scheme.primary : scheme.outline,
          tooltip: done ? 'Completed' : 'Mark done',
          onPressed: done ? null : () => _complete(context, ref),
        ),
        title: Text(
          task.title,
          style: done
              ? TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: scheme.onSurfaceVariant,
                )
              : null,
        ),
        subtitle: Row(
          children: [
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
            : _StatusChip(status: task.status),
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
    final choice = await showModalBottomSheet<TaskStatus>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Start'),
              onTap: () => Navigator.pop(context, TaskStatus.started),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Complete'),
              onTap: () => Navigator.pop(context, TaskStatus.completed),
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined),
              title: const Text('Reject'),
              onTap: () => Navigator.pop(context, TaskStatus.rejected),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    switch (choice) {
      case TaskStatus.started:
        await service.start(task);
      case TaskStatus.completed:
        await service.complete(task);
      case TaskStatus.rejected:
        await service.reject(task);
      default:
        break;
    }
    ref.invalidate(tasksForDayProvider(day));
    ref.invalidate(tasksBetweenProvider); // calendar views
    // Refresh the ledger so the live tile timer reads the new started time.
    ref.invalidate(taskTransitionsProvider(task.id));
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
    if (startedAt == null) return _StatusChip(status: widget.task.status);

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
  const _StatusChip({required this.status});
  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    return Text(status.name, style: Theme.of(context).textTheme.labelSmall);
  }
}
