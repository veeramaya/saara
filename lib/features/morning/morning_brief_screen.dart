import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../providers.dart';
import '../common/daily_quote_card.dart';
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
          const DailyQuoteCard(morning: true),
          tasksAsync.maybeWhen(
            data: (tasks) => _WhatsInStore(tasks: tasks),
            orElse: () => const SizedBox.shrink(),
          ),
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

/// §7.3 "What's in store" — the day opens forward-looking: how many words you
/// have given for today and when the first timed one lands. A quiet, encouraging
/// glance before you look back at yesterday.
class _WhatsInStore extends StatelessWidget {
  const _WhatsInStore({required this.tasks});
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final count = tasks.length;
    final timed =
        tasks.where((t) => t.scheduledStart != null).toList()
          ..sort((a, b) => a.scheduledStart!.compareTo(b.scheduledStart!));
    final first = timed.isEmpty ? null : timed.first;

    final String line;
    if (count == 0) {
      line = 'A clear day ahead. Give your word to what matters most.';
    } else {
      final noun = count == 1 ? 'commitment' : 'commitments';
      line = first == null
          ? '$count $noun for today.'
          : '$count $noun for today — first at '
                '${DateFormat.jm().format(first.scheduledStart!)}: '
                '${first.title}.';
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.wb_twilight, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "What's in store",
                    style: text.labelMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    line,
                    style: text.titleMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
