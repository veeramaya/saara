import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../providers.dart';

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
      appBar: AppBar(title: const Text('Complete your day')),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tasks) {
          final remaining = tasks
              .where((t) => openStatuses.contains(t.status))
              .toList();
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
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
    await db
        .into(db.dayLogs)
        .insertOnConflictUpdate(
          DayLogsCompanion.insert(date: key, closedAt: Value(DateTime.now())),
        );
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
            Text(task.title, style: Theme.of(context).textTheme.titleMedium),
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
