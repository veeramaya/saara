import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../domain/measurable_progress.dart';
import '../common/task_status_icon.dart';
import '../../providers.dart';
import '../task_detail/task_detail_screen.dart';
import 'add_result_screen.dart';
import 'area_icons.dart';

/// §7.5 Area page — purpose statement + this area's tasks. Measurable results
/// with verification and the capture timeline arrive in the next chunks.
class AreaDetailScreen extends ConsumerWidget {
  const AreaDetailScreen({super.key, required this.areaId});

  final String areaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areaAsync = ref.watch(areaByIdProvider(areaId));
    final tasksAsync = ref.watch(tasksForAreaProvider(areaId));

    return Scaffold(
      body: areaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (area) {
          if (area == null) {
            return const Center(child: Text('Area not found.'));
          }
          final accent =
              areaColor(area.color) ?? Theme.of(context).colorScheme.primary;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(area.displayName),
                backgroundColor: accent.withValues(alpha: 0.12),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: accent.withValues(alpha: 0.18),
                            child: Icon(areaIcon(area.icon), color: accent),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            area.baseCategory.name,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _PurposeCard(area: area),
                      const SizedBox(height: 16),
                      _ResultsSection(areaId: area.id, accent: accent),
                      const SizedBox(height: 16),
                      Text(
                        'Tasks',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              tasksAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e')),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('No tasks in this area yet.'),
                      ),
                    );
                  }
                  return SliverList.builder(
                    itemCount: tasks.length,
                    itemBuilder: (_, i) => _AreaTaskTile(task: tasks[i]),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _PurposeCard extends ConsumerWidget {
  const _PurposeCard({required this.area});
  final Area area;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purpose = area.purposeStatement;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.flag_outlined),
        title: const Text('Purpose'),
        subtitle: Text(
          purpose == null || purpose.isEmpty
              ? 'Tap to declare what this area is for.'
              : purpose,
        ),
        trailing: const Icon(Icons.edit, size: 18),
        onTap: () async {
          final controller = TextEditingController(text: purpose);
          final result = await showDialog<String>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Purpose statement'),
              content: TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. Be strong and energetic at 60',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, controller.text.trim()),
                  child: const Text('Save'),
                ),
              ],
            ),
          );
          if (result == null) return;
          await ref.read(areaDaoProvider).setPurpose(area.id, result);
          ref.invalidate(areaByIdProvider(area.id));
        },
      ),
    );
  }
}

class _ResultsSection extends ConsumerWidget {
  const _ResultsSection({required this.areaId, required this.accent});
  final String areaId;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(areaResultsProvider(areaId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Measurable results',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddResultScreen(areaId: areaId),
                ),
              ),
            ),
          ],
        ),
        async.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('$e'),
          data: (list) {
            if (list.isEmpty) {
              return Text(
                'No targets yet. Add one (e.g. "Walk 8,000 steps", daily) and '
                'log it to fill this area\'s ring.',
                style: Theme.of(context).textTheme.bodySmall,
              );
            }
            return Column(
              children: [
                for (final rp in list)
                  _ResultCard(record: rp, areaId: areaId, accent: accent),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ResultCard extends ConsumerWidget {
  const _ResultCard({
    required this.record,
    required this.areaId,
    required this.accent,
  });
  final ResultWithProgress record;
  final String areaId;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = record.$1;
    final progress = record.$2;
    // The user's own label wins — it says what the number means to them and
    // their listener; the metric-derived one is only a fallback.
    final unit = (result.unit?.trim().isNotEmpty ?? false)
        ? result.unit!.trim()
        : metricUnit(result.metricType);
    final aggStr = _fmt(progress.aggregate);
    final tgtStr = _fmt(progress.target);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  '${(progress.fraction * 100).round()}%',
                  style: TextStyle(color: accent, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit result',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          AddResultScreen(areaId: areaId, editing: result),
                    ),
                  ),
                ),
              ],
            ),
            // §3.2 deadline: shown with the move count, so a target that keeps
            // sliding is visible next to its progress bar.
            if (result.endDate != null)
              Text(
                'Due ${DateFormat('d MMM yyyy').format(result.endDate!)}'
                '${result.deadlineMoves > 0 ? ' · moved ${result.deadlineMoves}×' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: result.endDate!.isBefore(DateTime.now())
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.fraction,
              color: accent,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$aggStr / $tgtStr${unit.isEmpty ? '' : ' $unit'} · '
                  '${result.cadence.name}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                FilledButton.tonal(
                  onPressed: () => _log(context, ref, result),
                  child: const Text('Log'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  Future<void> _log(
    BuildContext context,
    WidgetRef ref,
    MeasurableResult result,
  ) async {
    final isBool = result.metricType == MetricType.boolean;
    double? value;
    if (isBool) {
      value = 1;
    } else {
      final controller = TextEditingController();
      value = await showDialog<double>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Log — ${result.title}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText:
                  'Value${metricUnit(result.metricType).isEmpty ? '' : ' (${metricUnit(result.metricType)})'}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                double.tryParse(controller.text.trim()),
              ),
              child: const Text('Log'),
            ),
          ],
        ),
      );
    }
    if (value == null) return;
    final now = DateTime.now();
    await ref
        .read(areaDaoProvider)
        .addLog(
          MeasurableLogsCompanion.insert(
            id: ref.read(uuidProvider).v4(),
            resultId: result.id,
            date: dayKey(now),
            value: value,
            createdAt: now,
          ),
        );
    ref.invalidate(areaResultsProvider(areaId));
    ref.invalidate(areaScoresProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logged to ${result.title}')));
    }
  }
}

class _AreaTaskTile extends StatelessWidget {
  const _AreaTaskTile({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final when = task.scheduledStart ?? task.dueDate;
    return ListTile(
      leading: TaskStatusIcon(status: task.status, due: when),
      title: Text(
        task.title,
        style: taskStatusClosed(task.status)
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Text(
        [
          if (task.publicationState == PublicationState.draft) 'draft',
          taskStatusLabel(task.status, when),
          if (when != null) DateFormat.MMMd().format(when),
        ].join(' · '),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
      ),
    );
  }
}
