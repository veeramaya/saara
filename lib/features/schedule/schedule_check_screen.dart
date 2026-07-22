import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:table_calendar/table_calendar.dart' show CalendarFormat;

import '../../data/database.dart';
import '../../domain/schedule_conflicts.dart';
import '../../providers.dart';
import '../../services/notification_service.dart';
import '../calendar/calendar_screen.dart';

/// §8 Saara's schedule check — shows where two items share time, and hands the
/// decision to the user.
///
/// Deliberately **not** prescriptive. Overlapping is often intentional: a call
/// while walking, a chat with a friend on the way somewhere. Saara cannot rank
/// your commitments — it has no way to know that kitchen work matters less than
/// a meeting, and frequently it doesn't. So this screen highlights the overlap,
/// offers to open it in the calendar where it can be judged in context, and
/// lets the user keep it as-is. Rescheduling is one option, not the answer.
class ScheduleCheckScreen extends ConsumerWidget {
  const ScheduleCheckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(scheduleConflictsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule check'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(scheduleConflictsProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (conflicts) {
          if (conflicts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Nothing overlapping in your next two weeks.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                child: Text(
                  '${conflicts.length} overlap'
                  '${conflicts.length == 1 ? '' : 's'} in the next two weeks. '
                  'Plenty of overlaps are deliberate — these are flagged so '
                  'nothing catches you out, not because they\'re wrong. '
                  'Open one to see it in your calendar, or keep it as it is.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              for (final c in conflicts) _ConflictTile(conflict: c),
            ],
          );
        },
      ),
    );
  }
}

class _ConflictTile extends ConsumerStatefulWidget {
  const _ConflictTile({required this.conflict});
  final ScheduleConflict conflict;

  @override
  ConsumerState<_ConflictTile> createState() => _ConflictTileState();
}

class _ConflictTileState extends ConsumerState<_ConflictTile> {
  bool _busy = false;

  String _fmt(DateTime d) => DateFormat('EEE, MMM d · h:mm a').format(d);

  /// Land the user on the day of the overlap so they can judge it in context —
  /// seeing what else is around it is usually what decides whether it matters.
  void _openInCalendar() {
    final day = widget.conflict.earlier.scheduledStart!;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CalendarScreen(
          initialDate: DateTime(day.year, day.month, day.day),
          initialFormat: CalendarFormat.week,
        ),
      ),
    );
  }

  /// "This overlap is fine." Saara records the answer and stops raising this
  /// pair — multitasking is a legitimate choice, not a problem to be resolved.
  Future<void> _keepBoth() async {
    final c = widget.conflict;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(appSettingsProvider).keepOverlap(c.key);
    ref.invalidate(scheduleConflictsProvider);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Kept as is — Saara won\'t raise this one again.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await ref.read(appSettingsProvider).unkeepOverlap(c.key);
            ref.invalidate(scheduleConflictsProvider);
          },
        ),
      ),
    );
  }

  Future<void> _apply() async {
    final c = widget.conflict;
    setState(() => _busy = true);
    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    try {
      await (db.update(db.tasks)..where((t) => t.id.equals(c.later.id))).write(
        TasksCompanion(
          scheduledStart: Value(c.suggestedStart),
          dueDate: Value(c.suggestedStart),
          updatedAt: Value(now),
        ),
      );
      if (c.later.reminderOffsets != null &&
          c.later.reminderOffsets!.isNotEmpty) {
        await NotificationService.instance.scheduleTaskReminder(
          taskId: c.later.id,
          title: c.later.title,
          when: c.suggestedStart,
          offsetsMinutes: c.later.reminderOffsets!,
        );
      }
      ref.invalidate(scheduleConflictsProvider);
      ref.invalidate(
        tasksForDayProvider(DateTime(now.year, now.month, now.day)),
      );
      unawaited(() async {
        try {
          if (await ref.read(googleSyncServiceProvider).isConnected()) {
            await ref.read(googleSyncOrchestratorProvider).syncAll();
          }
        } catch (_) {}
      }());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Moved “${c.later.title}” to ${_fmt(c.suggestedStart)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conflict;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_busy, color: scheme.tertiary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Overlap',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('“${c.earlier.title}” — ${_fmt(c.earlier.scheduledStart!)}'),
            Text('“${c.later.title}” — ${_fmt(c.later.scheduledStart!)}'),
            const SizedBox(height: 14),
            // The two real choices, given equal weight: look at it, or accept
            // it. Neither is Saara telling the user what their priorities are.
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: const Text('Open in calendar'),
                    onPressed: _busy ? null : _openInCalendar,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Keep both'),
                    onPressed: _busy ? null : _keepBoth,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // A reschedule is available for when the user wants it — offered
            // quietly, as one option, not as the verdict.
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _busy ? null : _apply,
                child: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Or move “${c.later.title}” to '
                        '${DateFormat('h:mm a').format(c.suggestedStart)}',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
