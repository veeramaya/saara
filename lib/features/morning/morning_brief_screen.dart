import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../providers.dart';
import '../home/widgets/task_tile.dart';

/// §7.3 Morning brief — "Open your day". Today's plan, plus **yesterday's open
/// items demanding a disposition** (reschedule/reject/missed — no silent
/// carryover, §4). CTA: "Commit to today" → DayLog.committed_at (§3.6).
///
/// Conflict flags and travel-time warnings (§7.3) depend on Calendar/location
/// which arrive in Phase 2/3; the layout leaves room for them.
class MorningBriefScreen extends ConsumerWidget {
  const MorningBriefScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final tasksAsync = ref.watch(tasksForDayProvider(day));
    final openAsync = ref.watch(openItemsBeforeProvider(day));

    return Scaffold(
      appBar: AppBar(title: const Text('Open your day')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          _SectionHeader(
            'Yesterday\'s open items',
            subtitle:
                'Give each a disposition — nothing carries over '
                'silently.',
          ),
          openAsync.when(
            loading: () => const _Loading(),
            error: (e, _) => _ErrorText(e),
            data: (items) => items.isEmpty
                ? const _AllClear('Nothing left open. Clean slate.')
                : Column(
                    children: [
                      for (final t in items) TaskTile(task: t, day: day),
                    ],
                  ),
          ),
          _SectionHeader(
            'Today',
            subtitle: DateFormat.yMMMMEEEEd().format(day),
          ),
          tasksAsync.when(
            loading: () => const _Loading(),
            error: (e, _) => _ErrorText(e),
            data: (tasks) => tasks.isEmpty
                ? const _AllClear('No tasks scheduled yet.')
                : Column(
                    children: [
                      for (final t in tasks) TaskTile(task: t, day: day),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: FilledButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Commit to today'),
          onPressed: () => _commit(context, ref, day),
        ),
      ),
    );
  }

  Future<void> _commit(
    BuildContext context,
    WidgetRef ref,
    DateTime day,
  ) async {
    final db = ref.read(appDatabaseProvider);
    final key = DateFormat('yyyy-MM-dd').format(day);
    final now = DateTime.now();
    // Upsert the DayLog with committed_at (§3.6, §7.3).
    await db
        .into(db.dayLogs)
        .insertOnConflictUpdate(
          DayLogsCompanion.insert(
            date: key,
            committedAt: Value(now),
            openedAt: Value(now),
          ),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Committed to today.')));
      Navigator.of(context).pop();
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (subtitle != null)
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(24),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.error);
  final Object error;
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.all(16), child: Text('Error: $error'));
}

class _AllClear extends StatelessWidget {
  const _AllClear(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
    child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
  );
}

// Value/DayLogsCompanion come from Drift; import kept via database.dart re-export.
