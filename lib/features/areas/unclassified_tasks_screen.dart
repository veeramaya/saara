import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../providers.dart';
import '../task_detail/task_detail_screen.dart';

/// §7.5 the Unclassified bucket: every actionable task that has no area, with
/// inline filing. A task without an area is invisible to the wheel and its
/// score, so this is where you sweep them into the right place — one tap each.
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
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: tasks.length,
            separatorBuilder: (_, i) => const Divider(height: 1),
            itemBuilder: (_, i) => _UnclassifiedRow(task: tasks[i], areas: areas),
          );
        },
      ),
    );
  }
}

class _UnclassifiedRow extends ConsumerWidget {
  const _UnclassifiedRow({required this.task, required this.areas});
  final Task task;
  final List<Area> areas;

  Future<void> _fileUnder(WidgetRef ref, String areaId) async {
    // Re-filing an unfiled task is still a correction in the ledger — the
    // adjusting entry records where it landed, same as any re-file (§4.3).
    await ref.read(taskServiceProvider).correctArea(task, areaId);
    ref.invalidate(unclassifiedTasksProvider);
    ref.invalidate(allTasksProvider);
    ref.invalidate(areaScoresProvider);
    final now = DateTime.now();
    ref.invalidate(tasksForDayProvider(DateTime(now.year, now.month, now.day)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final when = task.scheduledStart ?? task.dueDate;
    final subtitle = <String>[
      if (when != null) DateFormat('MMM d').format(when),
      task.status.name,
    ].join(' · ');

    return ListTile(
      title: Text(
        task.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(subtitle),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
      ),
      trailing: areas.isEmpty
          ? null
          : PopupMenuButton<String>(
              tooltip: 'File under…',
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
                      'File',
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
