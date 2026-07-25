import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../providers.dart';
import '../task_detail/task_detail_screen.dart';

/// §7.5 the Unclassified bucket: every actionable task that has no area, with
/// inline filing.
///
/// Repeats and recurring occurrences are **grouped by title**, so a weekly call
/// shows once — not one row per date. You file the whole group in a single tap,
/// which is what "classify this task" means to a person; otherwise filing one
/// occurrence left its siblings behind and it looked like nothing happened.
class UnclassifiedTasksScreen extends ConsumerWidget {
  const UnclassifiedTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(unclassifiedTasksProvider);
    final areas = ref.watch(activeAreasProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Unclassified')),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Nothing unclassified — every task has an area.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          // One entry per title; the value is every area-less task under it.
          final groups =
              groupBy(tasks, (Task t) => t.title.trim()).entries.toList()..sort(
                (a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()),
              );
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: groups.length,
            separatorBuilder: (_, i) => const Divider(height: 1),
            itemBuilder: (_, i) =>
                _UnclassifiedRow(tasks: groups[i].value, areas: areas),
          );
        },
      ),
    );
  }
}

class _UnclassifiedRow extends ConsumerWidget {
  const _UnclassifiedRow({required this.tasks, required this.areas});

  /// All area-less tasks sharing one title (a single call, or a whole series).
  final List<Task> tasks;
  final List<Area> areas;

  Future<void> _fileUnder(WidgetRef ref, String areaId) async {
    final service = ref.read(taskServiceProvider);
    // File every occurrence — re-filing an unfiled task is a ledger correction
    // (§4.3), recorded per occurrence so the history stays truthful.
    for (final t in tasks) {
      await service.correctArea(t, areaId);
    }
    ref.invalidate(unclassifiedTasksProvider);
    ref.invalidate(allTasksProvider);
    ref.invalidate(areaScoresProvider);
    final now = DateTime.now();
    ref.invalidate(tasksForDayProvider(DateTime(now.year, now.month, now.day)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final first = tasks.first;
    final dates =
        tasks
            .map((t) => t.scheduledStart ?? t.dueDate)
            .whereType<DateTime>()
            .toList()
          ..sort();
    final count = tasks.length;
    final subtitle = <String>[
      if (count > 1)
        '$count dates'
      else if (dates.isNotEmpty)
        DateFormat('MMM d').format(dates.first),
      if (count > 1 && dates.isNotEmpty)
        'from ${DateFormat('MMM d').format(dates.first)}',
    ].join(' · ');

    return ListTile(
      title: Text(first.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      // Tapping opens the first occurrence; filing acts on the whole group.
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: first.id)),
      ),
      trailing: areas.isEmpty
          ? null
          : PopupMenuButton<String>(
              tooltip: count > 1 ? 'File all $count under…' : 'File under…',
              onSelected: (areaId) => _fileUnder(ref, areaId),
              itemBuilder: (_) => [
                for (final a in areas)
                  PopupMenuItem(value: a.id, child: Text(a.displayName)),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      count > 1 ? 'File all' : 'File',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
