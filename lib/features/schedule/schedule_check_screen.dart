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
          // A repeating overlap (two recurring series, or a series vs a fixed
          // item) collapses into ONE row, so moving/keeping it is a single
          // action for the whole series — not the same decision N times.
          final groups = _groupConflicts(conflicts);
          return ListView(
            // Add the system inset to the bottom so the last card's actions
            // clear the gesture nav bar on edge-to-edge Android.
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              12 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                child: Text(
                  '${groups.length} overlap'
                  '${groups.length == 1 ? '' : 's'} in the next two weeks. '
                  'Plenty of overlaps are deliberate — these are flagged so '
                  'nothing catches you out, not because they\'re wrong. '
                  'Open one to see it in your calendar, or keep it as it is.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              for (final g in groups) _ConflictTile(group: g),
            ],
          );
        },
      ),
    );
  }
}

/// One or more conflicts that are really the *same* recurring overlap, so they
/// can be resolved once. A group of size 1 is an ordinary one-off overlap.
class _Group {
  _Group(this.all);
  final List<ScheduleConflict> all;
  ScheduleConflict get rep => all.first;
  int get count => all.length;

  /// True when the [later] side is a recurring occurrence — so "move" can shift
  /// the whole series rather than this one date.
  bool get laterRecurs => rep.later.parentRecurringId != null;
}

/// Collapse conflicts so a repeating overlap is one row. Two recurring series
/// group by their template pair; a series overlapping a fixed item groups by
/// (series, fixed id); a plain one-off overlap stays on its own.
List<_Group> _groupConflicts(List<ScheduleConflict> conflicts) {
  String gkey(ScheduleConflict c) {
    final e = c.earlier.parentRecurringId;
    final l = c.later.parentRecurringId;
    if (e != null && l != null) {
      final s = [e, l]..sort();
      return 'series:${s[0]}|${s[1]}';
    }
    if (e != null) {
      final s = [e, c.later.id]..sort();
      return 'mix:${s[0]}|${s[1]}';
    }
    if (l != null) {
      final s = [c.earlier.id, l]..sort();
      return 'mix:${s[0]}|${s[1]}';
    }
    return 'one:${c.key}';
  }

  final map = <String, List<ScheduleConflict>>{};
  for (final c in conflicts) {
    (map[gkey(c)] ??= []).add(c);
  }
  final groups = map.values.map((l) {
    l.sort(
      (a, b) => a.earlier.scheduledStart!.compareTo(b.earlier.scheduledStart!),
    );
    return _Group(l);
  }).toList()..sort(
    (a, b) =>
        a.rep.earlier.scheduledStart!.compareTo(b.rep.earlier.scheduledStart!),
  );
  return groups;
}

class _ConflictTile extends ConsumerStatefulWidget {
  const _ConflictTile({required this.group});
  final _Group group;

  @override
  ConsumerState<_ConflictTile> createState() => _ConflictTileState();
}

class _ConflictTileState extends ConsumerState<_ConflictTile> {
  bool _busy = false;

  String _fmt(DateTime d) => DateFormat('EEE, MMM d · h:mm a').format(d);

  /// Land the user on the day of the overlap so they can judge it in context —
  /// seeing what else is around it is usually what decides whether it matters.
  void _openInCalendar() {
    final day = widget.group.rep.earlier.scheduledStart!;
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
    final g = widget.group;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final settings = ref.read(appSettingsProvider);
    // Keep every occurrence of this overlap in one go, so a repeating one is
    // accepted once — not the same answer every day.
    for (final c in g.all) {
      await settings.keepOverlap(c.key);
    }
    ref.invalidate(scheduleConflictsProvider);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          g.count > 1
              ? 'Kept as is — all ${g.count} dates. Saara won\'t raise this again.'
              : 'Kept as is — Saara won\'t raise this one again.',
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            for (final c in g.all) {
              await settings.unkeepOverlap(c.key);
            }
            ref.invalidate(scheduleConflictsProvider);
          },
        ),
      ),
    );
  }

  Future<void> _apply() async {
    final g = widget.group;
    final c = g.rep;
    setState(() => _busy = true);
    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    try {
      if (g.laterRecurs) {
        // Move the WHOLE series to the free time-of-day — one action clears
        // every repeat of this overlap, instead of rescheduling each date.
        await ref
            .read(taskDaoProvider)
            .applyToWholeSeries(
              templateId: c.later.parentRecurringId!,
              shared: const TasksCompanion(),
              newHour: c.suggestedStart.hour,
              newMinute: c.suggestedStart.minute,
            );
        ref.invalidate(materializeRecurringProvider);
      } else {
        await (db.update(
          db.tasks,
        )..where((t) => t.id.equals(c.later.id))).write(
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
      }
      ref.invalidate(scheduleConflictsProvider);
      ref.invalidate(allTasksProvider);
      ref.invalidate(tasksBetweenProvider);
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
        final at = DateFormat('h:mm a').format(c.suggestedStart);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              g.laterRecurs
                  ? 'Moved every “${c.later.title}” to $at'
                  : 'Moved “${c.later.title}” to ${_fmt(c.suggestedStart)}',
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
    final g = widget.group;
    final c = g.rep;
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
                    g.count > 1 ? 'Overlap · repeats ${g.count}×' : 'Overlap',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('“${c.earlier.title}” — ${_fmt(c.earlier.scheduledStart!)}'),
            Text('“${c.later.title}” — ${_fmt(c.later.scheduledStart!)}'),
            if (g.count > 1)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Repeats ${g.count} times in the next two weeks — one choice '
                  'here settles them all.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
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
                        g.laterRecurs
                            ? 'Or move the whole “${c.later.title}” series to '
                                  '${DateFormat('h:mm a').format(c.suggestedStart)}'
                            : 'Or move “${c.later.title}” to '
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
