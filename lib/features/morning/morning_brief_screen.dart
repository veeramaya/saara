import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../domain/daily_quote.dart';
import '../../providers.dart';
import '../common/daily_quote_card.dart';
import '../home/widgets/task_tile.dart';
import '../share/ritual_card_screen.dart';

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
      appBar: AppBar(
        title: const Text('Open your day'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Share to your listeners',
            onPressed: () {
              final tasks = tasksAsync.valueOrNull ?? const <Task>[];
              final count = tasks.length;
              final sworn = tasks.where((t) => t.priority > 0).length;
              final now = DateTime.now();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RitualCardScreen(
                    data: DayCardData(
                      day: day,
                      morningQuote: quoteForDay(now, morning: true),
                      eveningQuote: quoteForDay(now, morning: false),
                      declaration: count == 0
                          ? 'A clear day ahead.'
                          : '$count commitment${count == 1 ? '' : 's'} today.',
                      declarationSub: sworn > 0
                          ? '$sworn with my word on ${sworn == 1 ? 'it' : 'them'}.'
                          : null,
                      // The day isn't closed yet — the back face says so.
                      closed: false,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
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
            subtitle:
                'Star the words you give your word to — they lead your day.',
          ),
          tasksAsync.when(
            loading: () => const _Loading(),
            error: (e, _) => _ErrorText(e),
            data: (tasks) {
              if (tasks.isEmpty) {
                return const _AllClear('No tasks scheduled yet.');
              }
              // Sworn commitments lead the day (§7.3 "give your word"), then by
              // time; untimed tasks sink to the bottom.
              final sorted = [...tasks]..sort((a, b) {
                final sa = a.priority > 0, sb = b.priority > 0;
                if (sa != sb) return sa ? -1 : 1;
                final ta = a.scheduledStart ?? a.dueDate;
                final tb = b.scheduledStart ?? b.dueDate;
                if (ta == null && tb == null) return 0;
                if (ta == null) return 1;
                if (tb == null) return -1;
                return ta.compareTo(tb);
              });
              return Column(
                children: [
                  for (final t in sorted) _TodayItem(task: t, day: day),
                ],
              );
            },
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

/// §7.3 "Give your word" — a star to the left of each of today's tasks. Tapping
/// it marks the task as a core commitment you're standing on today (stored on
/// [Task.priority]); it then leads the list and is honored/restored first at
/// night.
class _TodayItem extends ConsumerWidget {
  const _TodayItem({required this.task, required this.day});
  final Task task;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final sworn = task.priority > 0;
    return Row(
      children: [
        IconButton(
          icon: Icon(sworn ? Icons.star_rounded : Icons.star_border_rounded),
          color: sworn ? scheme.primary : scheme.onSurfaceVariant,
          tooltip: sworn ? 'You gave your word' : 'Give your word',
          onPressed: () async {
            await ref.read(taskDaoProvider).setSworn(task.id, !sworn);
            ref.invalidate(tasksForDayProvider(day));
          },
        ),
        Expanded(child: TaskTile(task: task, day: day)),
      ],
    );
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
    final sworn = tasks.where((t) => t.priority > 0).length;
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
    final swornLine = sworn > 0
        ? "You've given your word to $sworn of them."
        : null;

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
                  if (swornLine != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: scheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            swornLine,
                            style: text.bodyMedium?.copyWith(
                              color: scheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
