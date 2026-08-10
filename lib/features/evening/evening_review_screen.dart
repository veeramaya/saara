import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../providers.dart';
import '../common/world_today_card.dart';
import '../share/ritual_card_screen.dart';
import '../sync/sync_status_chip.dart';

/// §7.4 Evening review — "Complete your day". One-tap disposition per remaining
/// task (complete / reschedule / reject / mark missed). `missed` is finalized
/// here, with the user seeing it (§4 — never silent). Streak/health scoring and
/// the Sunday weekly-report extension arrive with their phases (§13, §10).
class EveningReviewScreen extends ConsumerWidget {
  const EveningReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final tomorrow = day.add(const Duration(days: 1));
    final tasksAsync = ref.watch(tasksForDayProvider(day));
    final tomorrowAsync = ref.watch(tasksForDayProvider(tomorrow));

    const openStatuses = {
      TaskStatus.created,
      TaskStatus.started,
      TaskStatus.inProgress,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete your day'),
        actions: [
          const SyncStatusChip(),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Share to your listeners',
            onPressed: () async {
              final tasks = tasksAsync.valueOrNull ?? const <Task>[];
              final areas =
                  ref.read(activeAreasProvider).valueOrNull ?? const <Area>[];
              final key = DateFormat('yyyy-MM-dd').format(day);
              final log = await ref.read(appDatabaseProvider).dayLogFor(key);
              final declaration = log?.declaration;
              final restoration = log?.reflection;
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RitualCardScreen(
                    data: DayCardData.compute(
                      day: day,
                      tasks: tasks,
                      areas: areas,
                      closed: true,
                      declaration: declaration,
                      restoration: restoration,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tasks) {
          // The words you gave your word to (§7.3) come first in every list, so
          // the evening honors and restores them ahead of the rest.
          final remaining =
              tasks.where((t) => openStatuses.contains(t.status)).toList()
                ..sort(_swornFirst);
          // Honor: what you kept today. Restore: the words you broke today —
          // integrity is restoring them, not never breaking them (§4).
          final kept = tasks
              .where((t) => t.status == TaskStatus.completed)
              .length;
          final broken =
              tasks
                  .where(
                    (t) =>
                        t.status == TaskStatus.missed ||
                        t.status == TaskStatus.cancelled,
                  )
                  .toList()
                ..sort(_swornFirst);
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const WorldTodayCard(),
              if (kept > 0) _HonorCard(kept: kept),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  remaining.isEmpty
                      ? 'Every task has a disposition. Well done.'
                      : '${remaining.length} task(s) still need a disposition.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final t in remaining) _DispositionCard(task: t, day: day),
              if (broken.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    'Restore your word',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 2, 16, 6),
                  child: Text(
                    "Integrity isn't never breaking your word — it's restoring "
                    'it. Acknowledge it, make it right, and re-commit or let it '
                    'go cleanly.',
                  ),
                ),
                for (final t in broken) _RestoreCard(task: t, day: day),
              ],
              _ReflectionField(day: day),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Tomorrow',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              tomorrowAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (ts) => ts.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Nothing scheduled yet.'),
                      )
                    : Column(
                        children: [
                          for (final t in ts)
                            ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.arrow_forward,
                                size: 16,
                              ),
                              title: Text(t.title),
                              trailing: t.scheduledStart == null
                                  ? null
                                  : Text(
                                      DateFormat.jm().format(t.scheduledStart!),
                                    ),
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: FilledButton.icon(
          icon: const Icon(Icons.nightlight_round),
          label: const Text('Close the day'),
          onPressed: () => _closeDay(context, ref, day),
        ),
      ),
    );
  }

  Future<void> _closeDay(
    BuildContext context,
    WidgetRef ref,
    DateTime day,
  ) async {
    final db = ref.read(appDatabaseProvider);
    final key = DateFormat('yyyy-MM-dd').format(day);
    await db.markDayClosed(key);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _DispositionCard extends ConsumerWidget {
  const _DispositionCard({required this.task, required this.day});
  final Task task;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(taskServiceProvider);
    Future<void> refresh() async => ref.invalidate(tasksForDayProvider(day));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (task.priority > 0) _swornStar(context),
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Done'),
                  onPressed: () async {
                    await service.complete(task);
                    await refresh();
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.schedule, size: 18),
                  label: const Text('Reschedule'),
                  onPressed: () async {
                    final newStart = await _pickTomorrowMorning(context);
                    if (newStart == null) return;
                    await service.reschedule(task, newStart);
                    await refresh();
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Reject'),
                  onPressed: () async {
                    final reason = await _askReason(context);
                    await service.reject(task, reason: reason);
                    await refresh();
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  label: const Text('Missed'),
                  onPressed: () async {
                    // §4: presented to the user right here ⇒ legal to finalize.
                    await service.markMissed(task);
                    await refresh();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickTomorrowMorning(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day, 9);
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

/// Sworn commitments (§7.3 "give your word", stored on [Task.priority]) sort
/// ahead of the rest, so the evening honors and restores them first.
int _swornFirst(Task a, Task b) {
  final sa = a.priority > 0, sb = b.priority > 0;
  if (sa == sb) return 0;
  return sa ? -1 : 1;
}

/// A small star shown beside a task in the evening lists when it was one of the
/// words you gave your word to that morning.
Widget _swornStar(BuildContext context) => Padding(
  padding: const EdgeInsets.only(right: 6),
  child: Icon(
    Icons.star_rounded,
    size: 18,
    color: Theme.of(context).colorScheme.primary,
  ),
);

/// §7.4 One honest line of restoration for the whole day — not per task (that's
/// notes/captures), just a simple daily gesture. Autosaves as you type, keyed by
/// the day, device-local. It rides along onto the shareable card.
class _ReflectionField extends ConsumerStatefulWidget {
  const _ReflectionField({required this.day});
  final DateTime day;

  @override
  ConsumerState<_ReflectionField> createState() => _ReflectionFieldState();
}

class _ReflectionFieldState extends ConsumerState<_ReflectionField> {
  final _controller = TextEditingController();
  Timer? _debounce;

  String get _key => DateFormat('yyyy-MM-dd').format(widget.day);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(appDatabaseProvider);
    var v = (await db.dayLogFor(_key))?.reflection;
    // Migrate an older device-local value into the synced day record.
    if (v == null || v.isEmpty) {
      final legacy = await ref.read(appSettingsProvider).ritualReflection(_key);
      if (legacy != null && legacy.isNotEmpty) {
        v = legacy;
        await db.setDayReflection(_key, legacy);
      }
    }
    if (mounted && v != null && v.isNotEmpty) _controller.text = v;
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(appDatabaseProvider).setDayReflection(_key, v);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restore your day',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              'One honest line — that\'s all. The task-level detail already '
              'lives in your notes and captures.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              onChanged: _onChanged,
              maxLines: 2,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. I let two slip; I owned it and I begin again.',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// §4 Honor — acknowledge what you kept today before anything else.
class _HonorCard extends StatelessWidget {
  const _HonorCard({required this.kept});
  final int kept;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.emoji_events_outlined, color: scheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'You kept your word $kept ${kept == 1 ? 'time' : 'times'} today.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// §4 Restore — a word you broke today. Integrity is honoring your word: keep
/// it, or as soon as you know you won't, acknowledge it, clean up the impact,
/// and re-commit or let it go cleanly.
class _RestoreCard extends ConsumerWidget {
  const _RestoreCard({required this.task, required this.day});
  final Task task;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: scheme.error),
            const SizedBox(width: 8),
            if (task.priority > 0) _swornStar(context),
            Expanded(
              child: Text(
                task.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.healing_outlined, size: 18),
              label: const Text('Restore'),
              onPressed: () => _restore(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final service = ref.read(taskServiceProvider);
    final note = TextEditingController();
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          // Clear both the keyboard (viewInsets) and the Android gesture bar
          // (padding) so the buttons are never hidden behind either.
          bottom:
              16 +
              MediaQuery.of(ctx).viewInsets.bottom +
              MediaQuery.of(ctx).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restore your word',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 2),
            Text(
              '“${task.title}”',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Acknowledge / clean it up (optional)',
                hintText: 'e.g. messaged them, apologised, moved it',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.event_repeat),
              label: const Text('Re-commit — give my word again'),
              onPressed: () => Navigator.pop(ctx, 'recommit'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.done_all),
              label: const Text('Release it cleanly — let it go'),
              onPressed: () => Navigator.pop(ctx, 'release'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    final ack = note.text.trim().isEmpty ? 'restored' : note.text.trim();
    if (choice == 'recommit') {
      final fresh = await ref.read(taskDaoProvider).findById(task.id);
      if (fresh == null) return;
      // Reopen records the restoration in the ledger; then re-commit a time.
      await service.reopen(fresh, note: 'Restored: $ack');
      if (!context.mounted) return;
      final when = await _pickWhen(context);
      if (when != null) {
        final again = await ref.read(taskDaoProvider).findById(task.id);
        if (again != null) await service.reschedule(again, when);
      }
    } else {
      // Release cleanly = an acknowledged decline, excluded from the score.
      await service.reject(task, reason: 'Released honestly: $ack');
    }
    ref.invalidate(tasksForDayProvider(day));
    ref.invalidate(reportSummaryProvider);
    ref.invalidate(areaScoresProvider);
  }

  Future<DateTime?> _pickWhen(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day, 9);
  }
}
