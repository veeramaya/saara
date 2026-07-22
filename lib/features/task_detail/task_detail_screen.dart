import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../domain/sense_interpreter.dart';
import '../../providers.dart';
import '../../services/geofence_service.dart';
import '../../services/google/meeting_note_tag.dart';
import '../../services/notification_service.dart';
import '../agenda/agenda_run_screen.dart';
import '../capture/review_items_screen.dart';
import '../captures/captures_section.dart';
import '../reports/event_report_screen.dart';
import '../share/invite_card_screen.dart';
import 'duplicate_event.dart';
import '../common/sense_animation.dart';
import '../task_card/task_card_screen.dart';

/// Task lifecycle screen (§4). Surfaces the full disposition set —
/// created → started → in_progress → completed, plus reschedule / reject /
/// missed — and shows the integrity-ledger history (§3.3) with timings.
class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  static const _openStatuses = {
    TaskStatus.created,
    TaskStatus.started,
    TaskStatus.inProgress,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskByIdProvider(taskId));
    final historyAsync = ref.watch(taskTransitionsProvider(taskId));

    final editable = taskAsync.valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task'),
        actions: [
          if (editable != null && editable.kind == TaskKind.event) ...[
            IconButton(
              icon: const Icon(Icons.summarize_outlined),
              tooltip: 'Event report',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EventReportScreen(eventId: taskId),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_all_outlined),
              tooltip: 'Duplicate to another date',
              onPressed: () => _duplicate(context, ref, editable),
            ),
          ],
          if (editable != null && _openStatuses.contains(editable.status))
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TaskCardScreen(editing: editable),
                ),
              ),
            ),
          if (editable != null)
            IconButton(
              icon: const Icon(Icons.ios_share),
              tooltip: 'Share as card',
              onPressed: () {
                final areas =
                    ref.read(activeAreasProvider).valueOrNull ?? const [];
                // The card is themed to the task's area — its icon and colour.
                final area = editable.areaId == null
                    ? null
                    : areas.where((a) => a.id == editable.areaId).firstOrNull;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InviteCardScreen(
                      task: editable,
                      areaName: area?.displayName,
                      areaIconName: area?.icon,
                      areaColor: area?.color,
                    ),
                  ),
                );
              },
            ),
          if (editable != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: () => _deleteTask(context, ref, editable),
            ),
        ],
      ),
      body: taskAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (task) {
          if (task == null) {
            return const Center(child: Text('Task not found.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                task.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              _StatusLine(task: task),
              if (task.parentEventId != null) ...[
                const SizedBox(height: 8),
                _ParentEventLink(eventId: task.parentEventId!),
              ],
              if (task.status == TaskStatus.started ||
                  task.status == TaskStatus.inProgress) ...[
                const SizedBox(height: 12),
                _TaskTimer(task: task),
              ],
              const SizedBox(height: 16),
              _schedule(context, task),
              const SizedBox(height: 8),
              _AreaRow(task: task),
              const SizedBox(height: 8),
              _Participants(taskId: taskId),
              if (task.kind == TaskKind.event) ...[
                const SizedBox(height: 16),
                _ActionItemsSection(event: task),
              ],
              if (task.meetingLink != null) ...[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.videocam),
                  label: const Text('Join meeting'),
                  onPressed: () => launchUrl(
                    Uri.parse(task.meetingLink!),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
              if (task.documentLink != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Open document'),
                  onPressed: () => launchUrl(
                    Uri.parse(task.documentLink!),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
              if (task.attachmentImagePath != null) ...[
                const SizedBox(height: 12),
                _AttachedImage(path: task.attachmentImagePath!),
              ],
              const Divider(height: 32),
              _NotesEditor(
                taskId: taskId,
                initial: task.notes,
                label: task.parentEventId != null ? 'Speaker notes' : 'Notes',
                hint: task.parentEventId != null
                    ? 'What you want to say / cover in this segment — shown '
                          'while you run the agenda.'
                    : 'Anything worth remembering about this task.',
                review: false,
              ),
              if (task.kind == TaskKind.event) ...[
                const Divider(height: 32),
                _NotesEditor(
                  taskId: taskId,
                  initial: task.reviewNotes,
                  label: 'Review',
                  hint:
                      'How did it go? What worked, what to change next '
                      'time. Stays on your device — never synced.',
                  review: true,
                ),
              ],
              const Divider(height: 32),
              CapturesSection(taskId: taskId),
              const Divider(height: 32),
              Text('Actions', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _actions(context, ref, task),
              const Divider(height: 32),
              Text(
                'History (integrity ledger)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              historyAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (rows) => _history(context, rows),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _schedule(BuildContext context, Task task) {
    final when = task.scheduledStart ?? task.dueDate;
    return Row(
      children: [
        const Icon(Icons.schedule, size: 16),
        const SizedBox(width: 6),
        Text(
          when == null
              ? 'No date set'
              : DateFormat('EEE, MMM d · h:mm a').format(when),
        ),
        if (task.durationMin != null) ...[
          const SizedBox(width: 12),
          const Icon(Icons.timelapse, size: 16),
          const SizedBox(width: 6),
          Text('${task.durationMin} min'),
        ],
      ],
    );
  }

  /// Delete-scope chooser for a repeating task, mirroring Outlook / Google
  /// Calendar: This event · This and following events · All events. Returns
  /// 'one' | 'following' | 'series', or null on cancel.
  Future<String?> _pickRecurringScope(BuildContext context, String title) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Delete repeating task'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              '“$title” repeats. What do you want to delete?',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'one'),
            child: const _ScopeOption(
              icon: Icons.event_busy_outlined,
              label: 'This event',
              detail: 'Only this date',
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'following'),
            child: const _ScopeOption(
              icon: Icons.skip_next_outlined,
              label: 'This and following events',
              detail: 'This date and every later one',
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'series'),
            child: const _ScopeOption(
              icon: Icons.delete_sweep_outlined,
              label: 'All events',
              detail: 'The whole series, past and future',
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 12, 4),
              child: TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// §7 delete a task/event. **Soft** delete — it moves to Trash (Tasks →
  /// Deleted) and can be restored, and the next sync removes it from Google
  /// too. Deleting was previously only reachable through the Saara chat.
  Future<void> _deleteTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final isEvent = task.kind == TaskKind.event;
    final dao = ref.read(taskDaoProvider);
    final children = isEvent
        ? await dao.childTasksForEvent(task.id)
        : const <Task>[];
    // A repeating task is a template plus one row per occurrence. Deleting the
    // template alone only stops *future* expansion — the dates already on the
    // calendar stay, which reads as "delete didn't work" (§4).
    // Three shapes of "delete" for a repeating task:
    //  • template  (rrule, no parent)   → this is the series definition itself
    //  • occurrence (parentRecurringId) → one dated row the engine generated
    //  • plain task/event               → a single row
    // On the calendar you only ever see occurrences, so deleting one and
    // walking away leaves the template quietly generating the next date — which
    // reads as "delete didn't work / a new task keeps coming back". The fix is
    // to offer "Delete entire series" right from the occurrence.
    final isTemplate = task.rrule != null && task.parentRecurringId == null;
    final isOccurrence = task.parentRecurringId != null;
    final seriesId = isOccurrence ? task.parentRecurringId! : task.id;
    // Everything the series would remove — the template's live occurrences.
    final seriesInstances = (isTemplate || isOccurrence)
        ? await dao.instancesOfTemplate(seriesId)
        : const <Task>[];
    final occurrences = isTemplate ? seriesInstances.length : 0;
    if (!context.mounted) return;

    // For a repeating task, mirror Outlook / Google Calendar exactly — a
    // radio-style scope choice. Values:
    //   'one'       just this date
    //   'following' this date + all later ones, and stop repeating
    //   'series'    every date, past and future
    //   'stop'      (template screen) keep scheduled dates, stop repeating
    final String? choice;
    if (isOccurrence) {
      choice = await _pickRecurringScope(context, task.title);
    } else if (isTemplate && occurrences > 0) {
      choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Delete “${task.title}”?'),
          content: Text(
            'This task repeats, with $occurrences date'
            '${occurrences == 1 ? '' : 's'} still on your calendar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'stop'),
              child: const Text('Stop repeating only'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'series'),
              child: const Text('Delete all'),
            ),
          ],
        ),
      );
    } else {
      // §4.2 delete removes the future, never the past. Once something has
      // moved out of `created` it happened — it existed in your plan or your
      // execution — so the row can leave your lists but the record cannot.
      final hasHistory =
          task.publicationState == PublicationState.released &&
          task.status != TaskStatus.created;
      final childNote = children.isEmpty
          ? ''
          : '\n\nIts ${children.length} action '
                'item${children.length == 1 ? '' : 's'} stay in your task list.';

      choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            hasHistory ? 'Hide “${task.title}”?' : 'Delete “${task.title}”?',
          ),
          content: Text(
            hasHistory
                ? 'This has already happened, so it stays in your record — '
                      'your score is unchanged either way.\n\n'
                      'It leaves your lists and moves to Trash, where you can '
                      'restore it.$childNote'
                : task.publicationState == PublicationState.draft
                ? 'This is still a draft — nothing was committed and nothing '
                      'has been counted. It moves to Trash, where you can '
                      'restore it.$childNote'
                : 'You never started this, so nothing leaves your record. It '
                      'moves to Trash, where you can restore it. If it\'s '
                      'synced, it is removed from Google too.$childNote',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'one'),
              child: Text(hasHistory ? 'Hide from lists' : 'Delete'),
            ),
          ],
        ),
      );
    }
    if (choice == null) return;

    // Record the removal before performing it — the row leaves your lists, but
    // that it was removed is itself a fact worth keeping (§4.2).
    await ref.read(taskServiceProvider).recordDeleted(task);

    // Perform the delete for the chosen scope.
    final int removed;
    switch (choice) {
      case 'series': // every date — template + all occurrences
        removed = await dao.softDeleteCascade(seriesId, instances: true);
      case 'following': // this date + later, and stop repeating
        removed = await dao.softDeleteThisAndFollowing(
          seriesId,
          task.scheduledStart ?? task.dueDate ?? DateTime.now(),
        );
      case 'stop': // template only — keep scheduled dates, stop repeating
        removed = await dao.softDeleteCascade(task.id, instances: false);
      default: // 'one' — this single row
        removed = await dao.softDeleteCascade(task.id, instances: false);
    }
    await NotificationService.instance.cancelTaskReminder(task.id);
    await SaaraGeofence.remove(task.id);
    // Series/following delete touches other rows too — clear their reminders so
    // a deleted date can't still buzz the phone.
    if (choice == 'series' || choice == 'following') {
      await NotificationService.instance.cancelTaskReminder(seriesId);
      await SaaraGeofence.remove(seriesId);
      for (final i in seriesInstances) {
        await NotificationService.instance.cancelTaskReminder(i.id);
        await SaaraGeofence.remove(i.id);
      }
    }

    ref.invalidate(allTasksProvider);

    ref.invalidate(unscheduledTasksProvider);
    ref.invalidate(deletedTasksProvider);
    ref.invalidate(childTaskCountsProvider);
    // Invalidate the *whole* families, not one computed key: the calendar
    // (week/2-week/month) reads tasksBetween over ranges we can't guess, so
    // keying by the task's own day left the deleted row on screen there.
    ref.invalidate(tasksForDayProvider);
    ref.invalidate(tasksBetweenProvider);
    ref.invalidate(scheduleConflictsProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          removed > 1
              ? 'Deleted “${task.title}” and $removed dates — restore from Trash'
              : 'Deleted “${task.title}” — restore from Trash',
        ),
      ),
    );
    navigator.pop();
  }

  /// §4 clone this event onto another date, carrying its agenda. Every action
  /// item shifts by the same offset, so a 6–11 PM run-of-show lands intact.
  Future<void> _duplicate(
    BuildContext context,
    WidgetRef ref,
    Task event,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final oldStart = event.scheduledStart ?? event.dueDate ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: oldStart.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      helpText: 'Duplicate to which date?',
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(oldStart),
      helpText: 'Start time',
    );
    if (!context.mounted) return;

    final newStart = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? oldStart.hour,
      time?.minute ?? oldStart.minute,
    );
    try {
      final copied = await duplicateEventToDate(
        ref,
        event: event,
        newStart: newStart,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Duplicated to ${DateFormat('EEE, MMM d').format(newStart)}'
            '${copied == 0 ? '' : ' with $copied action item'
                      '${copied == 1 ? '' : 's'}'}',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not duplicate: $e')),
      );
    }
  }

  Widget _actions(BuildContext context, WidgetRef ref, Task task) {
    final service = ref.read(taskServiceProvider);
    Future<void> run(Future<void> Function() op) async {
      try {
        await op();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
      _refresh(ref, task);
    }

    if (!_openStatuses.contains(task.status)) {
      // §4 completed/missed are reversible — an accidental one-tap check-off
      // must not be a dead end. Reopening is recorded in the ledger.
      final reopenable =
          task.status == TaskStatus.completed ||
          task.status == TaskStatus.missed;
      return Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    reopenable
                        ? Icons.check_circle_outline
                        : Icons.lock_outline,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text('This task is ${task.status.name}.')),
                ],
              ),
              if (reopenable) ...[
                const SizedBox(height: 12),
                Text(
                  'Marked it by mistake, or need more time? Reopening puts it '
                  'back in progress and is recorded in the history.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reopen'),
                    onPressed: () => run(() => service.reopen(task)),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (task.status == TaskStatus.created)
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
            onPressed: () => run(() => service.start(task)),
          ),
        if (task.status == TaskStatus.started)
          FilledButton.icon(
            icon: const Icon(Icons.work_history),
            label: const Text('Mark in progress'),
            onPressed: () => run(() => service.beginWork(task)),
          ),
        // Outlined, and phrased as an instruction. A tinted button with a tick
        // reads as a *state* — "this is complete" — not an action, and next to
        // a status chip saying "created" that is genuinely confusing. Only the
        // natural next step (Start / Mark in progress) is filled; everything
        // else here is an equal alternative.
        OutlinedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Mark complete'),
          onPressed: () => _complete(context, ref, task),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.schedule),
          label: const Text('Reschedule'),
          onPressed: () async {
            final newStart = await _pickDateTime(context, task);
            if (newStart == null) return;
            await run(() => service.reschedule(task, newStart));
          },
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Reject'),
          onPressed: () async {
            final reason = await _askReason(context);
            await run(() => service.reject(task, reason: reason));
          },
        ),
      ],
    );
  }

  Widget _history(BuildContext context, List<TaskTransition> rows) {
    if (rows.isEmpty) {
      return const Text('No transitions yet — the task was just created.');
    }
    final fmt = DateFormat('MMM d, h:mm a');
    return Column(
      children: [
        for (final r in rows)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history, size: 18),
            title: Text('${r.fromStatus?.name ?? 'new'} → ${r.toStatus.name}'),
            subtitle: r.note == null ? null : Text(r.note!),
            trailing: Text(
              fmt.format(r.at),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
      ],
    );
  }

  /// Complete + celebrate (§8/§13): mark done, credit Saara's assist (+1),
  /// then play the task's contextual sense resolving into the reliability ring.
  Future<void> _complete(BuildContext context, WidgetRef ref, Task task) async {
    try {
      await ref.read(taskServiceProvider).complete(task);
      await NotificationService.instance.cancelTaskReminder(task.id);
      await SaaraGeofence.remove(task.id);
      await ref.read(appSettingsProvider).bumpSaaraValue();
      var areaName = 'Integrity';
      if (task.areaId != null) {
        final area = await ref.read(areaByIdProvider(task.areaId!).future);
        if (area != null) areaName = area.displayName;
      }
      ref.invalidate(areaScoresProvider);
      ref.invalidate(overallEffectivenessProvider);
      ref.invalidate(saaraValueProvider);
      final pct = await ref.read(overallEffectivenessProvider.future);
      if (context.mounted) {
        await showCompletionCelebration(
          context,
          sense: senseForTask('${task.title} ${task.notes ?? ''}'),
          areaName: areaName,
          overallPct: pct,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    _refresh(ref, task);
    unawaited(_quietSync(ref)); // push this completion to Google promptly
  }

  /// Fire-and-forget reconcile so a local change reaches Google without waiting
  /// for the periodic auto-sync (§9). Silent — never blocks or disrupts the UI.
  Future<void> _quietSync(WidgetRef ref) async {
    try {
      if (!await ref.read(googleSyncServiceProvider).isConnected()) return;
      await ref.read(googleSyncOrchestratorProvider).syncAll();
      final now = DateTime.now();
      ref.invalidate(
        tasksForDayProvider(DateTime(now.year, now.month, now.day)),
      );
    } catch (_) {}
  }

  void _refresh(WidgetRef ref, Task task) {
    ref.invalidate(taskByIdProvider(taskId));
    ref.invalidate(taskTransitionsProvider(taskId));
    final when = task.scheduledStart ?? task.dueDate;
    if (when != null) {
      ref.invalidate(
        tasksForDayProvider(DateTime(when.year, when.month, when.day)),
      );
    }
    if (task.areaId != null) {
      ref.invalidate(tasksForAreaProvider(task.areaId!));
    }
  }

  Future<DateTime?> _pickDateTime(BuildContext context, Task task) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: task.scheduledStart ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(task.scheduledStart ?? now),
    );
    return DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? 9,
      time?.minute ?? 0,
    );
  }

  Future<String?> _askReason(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reason (optional)'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'One line'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

/// §4 live stopwatch shown while a task is started / in progress. Counts up from
/// the first `started` transition in the ledger (survives app restarts), and —
/// when the task has a planned duration — shows time left and flags overrun, so
/// you can stay watchful and move on on time.
class _TaskTimer extends ConsumerStatefulWidget {
  const _TaskTimer({required this.task});
  final Task task;

  @override
  ConsumerState<_TaskTimer> createState() => _TaskTimerState();
}

class _TaskTimerState extends ConsumerState<_TaskTimer> {
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
    final neg = d.isNegative;
    d = d.abs();
    String two(int n) => n.toString().padLeft(2, '0');
    final base = d.inHours > 0
        ? '${d.inHours}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}'
        : '${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
    return neg ? '-$base' : base;
  }

  @override
  Widget build(BuildContext context) {
    final transitions =
        ref.watch(taskTransitionsProvider(widget.task.id)).valueOrNull ??
        const <TaskTransition>[];
    // The **latest** start, not the first: a reopened task restarts its clock
    // rather than showing hours of elapsed time from the original attempt.
    DateTime? startedAt;
    for (final t in transitions) {
      if (t.toStatus == TaskStatus.started &&
          (startedAt == null || t.at.isAfter(startedAt))) {
        startedAt = t.at;
      }
    }
    if (startedAt == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final elapsed = DateTime.now().difference(startedAt);
    final dur = widget.task.durationMin;
    final planned = dur == null ? null : Duration(minutes: dur);
    final over = planned != null && elapsed > planned;
    final accent = over ? scheme.error : scheme.primary;

    return Card(
      elevation: 0,
      color: accent.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(over ? Icons.alarm : Icons.timer_outlined, color: accent),
                const SizedBox(width: 12),
                Text(
                  _fmt(elapsed),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                if (planned != null)
                  Text(
                    'of ${dur}m',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
            if (planned != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (elapsed.inSeconds / planned.inSeconds).clamp(0.0, 1.0),
                minHeight: 8,
                color: accent,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Text(
                over
                    ? 'Over by ${_fmt(elapsed - planned)} — wrap up and move on.'
                    : '${_fmt(planned - elapsed)} left to stay on time.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: over ? scheme.error : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// §7 a roomy, auto-saving notes pane — used twice: as **speaker notes** on a
/// task (shown live in the agenda runner) and as an event's private **review**.
/// Saves ~700 ms after typing stops, so there's no Save button to forget.
class _NotesEditor extends ConsumerStatefulWidget {
  const _NotesEditor({
    required this.taskId,
    required this.initial,
    required this.label,
    required this.hint,
    required this.review,
  });

  final String taskId;
  final String? initial;
  final String label;
  final String hint;

  /// true → writes `reviewNotes` (never synced); false → `notes`.
  final bool review;

  @override
  ConsumerState<_NotesEditor> createState() => _NotesEditorState();
}

class _NotesEditorState extends ConsumerState<_NotesEditor> {
  late final TextEditingController _c;
  Timer? _debounce;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    // Hide the sync plumbing: an action item's note carries a "From meeting:"
    // line for cross-device relinking, which the user shouldn't have to see.
    _c = TextEditingController(
      text: widget.review ? widget.initial : stripMeetingLine(widget.initial),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    setState(() => _saved = false);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), _save);
  }

  Future<void> _save() async {
    final db = ref.read(appDatabaseProvider);
    final text = _c.text.trim();
    final value = text.isEmpty ? null : text;
    await (db.update(db.tasks)..where((t) => t.id.equals(widget.taskId))).write(
      widget.review
          ? TasksCompanion(
              reviewNotes: Value(value),
              updatedAt: Value(DateTime.now()),
            )
          // `notes` syncs to Google; the "From meeting:" line is re-appended on
          // push, so saving without it here is safe.
          : TasksCompanion(
              notes: Value(value),
              updatedAt: Value(DateTime.now()),
            ),
    );
    ref.invalidate(taskByIdProvider(widget.taskId));
    if (mounted) setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.label, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (_saved)
              Row(
                children: [
                  Icon(
                    Icons.check,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Saved',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _c,
          onChanged: _onChanged,
          minLines: 4,
          maxLines: 12,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: widget.hint,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}

/// §4 back-link from a meeting action item to its parent event.
class _ParentEventLink extends ConsumerWidget {
  const _ParentEventLink({required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(taskByIdProvider(eventId)).valueOrNull;
    if (event == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: eventId)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.event, size: 16, color: scheme.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'From meeting: ${event.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.primary),
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

/// §4 an event's action items — child tasks captured from its meeting. Each is
/// a normal task (scored under its area, inherited from the event by default).
/// Result of the timed add-action-item dialog.
typedef _NewItem = ({String title, DateTime? start, int? durationMin});

/// Dialog to add an agenda item with a start time + duration (§4). The start is
/// pre-filled with the previous item's end so a run-of-show chains back-to-back;
/// the user just types a title and a duration.
class _AddActionItemDialog extends StatefulWidget {
  const _AddActionItemDialog({required this.initialStart});
  final DateTime initialStart;

  @override
  State<_AddActionItemDialog> createState() => _AddActionItemDialogState();
}

class _AddActionItemDialogState extends State<_AddActionItemDialog> {
  final _title = TextEditingController();
  final _duration = TextEditingController(text: '15');
  late DateTime _start = widget.initialStart;

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    super.dispose();
  }

  int get _dur => int.tryParse(_duration.text.trim()) ?? 0;
  DateTime get _end => _start.add(Duration(minutes: _dur));

  Future<void> _pickStart() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (t == null) return;
    setState(
      () => _start = DateTime(
        _start.year,
        _start.month,
        _start.day,
        t.hour,
        t.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('h:mm a');
    return AlertDialog(
      title: const Text('Action item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _title,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. Create the context of the training',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text('Start ${fmt.format(_start)}'),
                  onPressed: _pickStart,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 84,
                child: TextField(
                  controller: _duration,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Min',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${fmt.format(_start)} – ${fmt.format(_end)}  ·  $_dur min',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (
            title: _title.text.trim(),
            start: _start,
            durationMin: _dur > 0 ? _dur : null,
          )),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _ActionItemsSection extends ConsumerWidget {
  const _ActionItemsSection({required this.event});
  final Task event;

  /// Next slot's default start = the latest end among existing items, else the
  /// event's start. Lets an agenda chain back-to-back with just a duration.
  DateTime _defaultStart(List<Task> items) {
    DateTime? latestEnd;
    for (final t in items) {
      final s = t.scheduledStart;
      if (s == null) continue;
      final e = s.add(Duration(minutes: t.durationMin ?? 0));
      if (latestEnd == null || e.isAfter(latestEnd)) latestEnd = e;
    }
    return latestEnd ?? event.scheduledStart ?? DateTime.now();
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final items =
        ref.read(childTasksForEventProvider(event.id)).valueOrNull ??
        const <Task>[];
    final result = await showDialog<_NewItem>(
      context: context,
      builder: (_) => _AddActionItemDialog(initialStart: _defaultStart(items)),
    );
    if (result == null || result.title.isEmpty) return;
    final now = DateTime.now();
    await ref
        .read(taskDaoProvider)
        .insertTask(
          TasksCompanion.insert(
            id: ref.read(uuidProvider).v4(),
            title: result.title,
            kind: const Value(TaskKind.task),
            parentEventId: Value(event.id),
            areaId: Value(event.areaId), // inherit the event's area for scoring
            scheduledStart: Value(result.start),
            dueDate: Value(result.start),
            durationMin: Value(result.durationMin),
            status: const Value(TaskStatus.created),
            source: const Value(TaskSource.conversation),
            createdAt: now,
            updatedAt: now,
          ),
        );
    ref.invalidate(childTasksForEventProvider(event.id));
    ref.invalidate(childTaskCountsProvider);
    ref.invalidate(allTasksProvider);
    ref.invalidate(unscheduledTasksProvider);
    final d = result.start;
    if (d != null) {
      ref.invalidate(tasksForDayProvider(DateTime(d.year, d.month, d.day)));
    }
  }

  /// "6:00 – 6:05 PM · 5 min" for a timed slot, else just the start time.
  String _slot(Task t) {
    final fmt = DateFormat('h:mm a');
    final s = t.scheduledStart!;
    final d = t.durationMin;
    if (d == null || d == 0) return fmt.format(s);
    final e = s.add(Duration(minutes: d));
    return '${fmt.format(s)} – ${fmt.format(e)} · $d min';
  }

  /// Photograph the meeting notes → AI extracts every action item → each is
  /// created under this event, defaulting to the event's area (§4/§11).
  Future<void> _fromNotes(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Photograph the notes'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pick a screenshot / photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewItemsScreen(
          imagePath: picked.path,
          parentEventId: event.id,
          fallbackAreaId: event.areaId,
        ),
      ),
    );
    ref.invalidate(childTasksForEventProvider(event.id));
    ref.invalidate(childTaskCountsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(childTasksForEventProvider(event.id));
    // Read the agenda in time order (timed items first, undated last).
    final items = [...(async.valueOrNull ?? const <Task>[])]
      ..sort((a, b) {
        final sa = a.scheduledStart, sb = b.scheduledStart;
        if (sa == null && sb == null) return a.createdAt.compareTo(b.createdAt);
        if (sa == null) return 1;
        if (sb == null) return -1;
        return sa.compareTo(sb);
      });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Action items${items.isEmpty ? '' : ' (${items.length})'}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Tasks that came out of this meeting.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              icon: const Icon(Icons.add_task),
              label: const Text('Add task'),
              onPressed: () => _add(context, ref),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('From notes'),
              onPressed: () => _fromNotes(context, ref),
            ),
          ],
        ),
        if (items.any(
          (t) =>
              t.status != TaskStatus.completed &&
              t.status != TaskStatus.rejected,
        )) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Start agenda'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AgendaRunScreen(
                    eventId: event.id,
                    eventTitle: event.title,
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 4),
        for (final t in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
              t.status == TaskStatus.completed
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              size: 20,
              color: t.status == TaskStatus.completed
                  ? Colors.green
                  : Theme.of(context).colorScheme.outline,
            ),
            title: Text(
              t.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.status == TaskStatus.completed
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
            subtitle: t.scheduledStart == null ? null : Text(_slot(t)),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: t.id)),
            ),
          ),
      ],
    );
  }
}

/// §11 on-device participants for the task (hidden when there are none).
class _Participants extends ConsumerWidget {
  const _Participants({required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(taskParticipantsProvider(taskId));
    return async.maybeWhen(
      data: (people) {
        if (people.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final p in people)
              Chip(
                avatar: const Icon(Icons.person, size: 16),
                label: Text(p.displayName),
              ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// §7.6 the original captured image, so the extraction can be verified against
/// the source. Tap to view full-screen.
class _AttachedImage extends StatelessWidget {
  const _AttachedImage({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Captured image', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.black,
              insetPadding: const EdgeInsets.all(12),
              child: InteractiveViewer(
                child: Image.file(File(path), fit: BoxFit.contain),
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(path),
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => const Text('Image unavailable'),
            ),
          ),
        ),
      ],
    );
  }
}

/// One row in the recurring delete-scope chooser: icon, bold label, subtext.
/// §4.3 which area this sits under, and the way to re-file it.
///
/// Re-filing something that already happened is a **correction**, not an edit:
/// the original posting stands and an adjusting entry is added beside it, so
/// reporting follows the correction without the past being quietly rewritten.
///
/// The everyday case this exists for: *watching a movie* filed under Health
/// when it belonged in Entertainment. The instinct is to delete it; the right
/// answer is to correct it.
class _AreaRow extends ConsumerWidget {
  const _AreaRow({required this.task});
  final Task task;

  bool get _hasHistory =>
      task.publicationState == PublicationState.released &&
      task.status != TaskStatus.created;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areas = ref.watch(activeAreasProvider).valueOrNull ?? const <Area>[];
    final area = areas.where((a) => a.id == task.areaId).firstOrNull;
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _refile(context, ref, areas),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(Icons.donut_small_outlined, size: 16, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              area?.displayName ?? 'Unclassified',
              style: TextStyle(
                color: area == null ? scheme.onSurfaceVariant : null,
                fontStyle: area == null ? FontStyle.italic : null,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.edit_outlined, size: 14, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Future<void> _refile(
    BuildContext context,
    WidgetRef ref,
    List<Area> areas,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final reason = TextEditingController();

    final picked = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_hasHistory ? 'Re-file this' : 'Choose an area'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_hasHistory)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'This already happened, so the original entry stays. '
                    'Saara adds a correction beside it and reports it under '
                    'the new area.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final a in areas)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(a.displayName),
                          trailing: a.id == task.areaId
                              ? const Icon(Icons.check, size: 18)
                              : null,
                          onTap: () => Navigator.pop(ctx, a.id),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Optional, never demanded, never scored — it exists only so the
              // user can notice their own patterns later (§4.4).
              TextField(
                controller: reason,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Why? (optional)',
                  hintText: 'recreation, not health',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (picked == null || picked == task.areaId) return;

    final text = reason.text.trim();
    await ref
        .read(taskServiceProvider)
        .correctArea(task, picked, reason: text.isEmpty ? null : text);

    ref.invalidate(taskByIdProvider(task.id));
    ref.invalidate(taskTransitionsProvider(task.id));
    ref.invalidate(areaScoresProvider);
    ref.invalidate(overallEffectivenessProvider);
    ref.invalidate(allTasksProvider);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _hasHistory
              ? 'Re-filed. The original entry stays in your record.'
              : 'Area updated.',
        ),
      ),
    );
  }
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.icon,
    required this.label,
    required this.detail,
  });
  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 22, color: scheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                detail,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (task.status) {
      TaskStatus.completed => Colors.green,
      TaskStatus.missed => scheme.error,
      TaskStatus.rejected => scheme.error,
      TaskStatus.rescheduled => scheme.tertiary,
      _ => scheme.primary,
    };
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            task.status.name,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
        const Spacer(),
        if (task.status == TaskStatus.completed &&
            task.timeToCompleteMin != null)
          Text(
            'Took ${task.timeToCompleteMin} min',
            style: Theme.of(context).textTheme.labelMedium,
          ),
      ],
    );
  }
}
