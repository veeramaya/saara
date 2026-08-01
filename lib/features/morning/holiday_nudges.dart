import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../domain/festival_theme.dart';
import '../../domain/holidays_india.dart';
import '../../providers.dart';

/// A gazetted holiday that's approaching with nothing planned around it — the
/// gap the morning nudge invites you to fill.
class HolidayNudge {
  const HolidayNudge(this.holiday, this.date, this.daysAway);
  final Holiday holiday;
  final DateTime date;
  final int daysAway;
}

/// Upcoming gazetted holidays (per the chosen region) within a two-week window
/// that have **no task or event planned around them** (±2 days). Saara empowers
/// you to plan; it never plans for you — so this only surfaces the gap, and only
/// when you've scheduled nothing near the day.
final holidayNudgesProvider = FutureProvider<List<HolidayNudge>>((ref) async {
  final now = DateTime.now();
  final region = await ref.watch(appSettingsProvider).ritualRegion();
  final upcoming = upcomingHolidays(now, region: region, withinDays: 14);
  if (upcoming.isEmpty) return const [];
  final dao = ref.watch(taskDaoProvider);
  final out = <HolidayNudge>[];
  for (final u in upcoming) {
    final d = DateTime(u.date.year, u.date.month, u.date.day);
    final around = await dao.tasksBetween(
      d.subtract(const Duration(days: 2)),
      d.add(const Duration(days: 3)),
    );
    if (around.isEmpty) out.add(HolidayNudge(u.holiday, u.date, u.daysAway));
  }
  return out;
});

/// §7.3 The morning look-ahead. Polite invitations, never demands: a festival is
/// near and your calendar is empty around it. You plan it your way, or you don't.
class HolidayNudges extends ConsumerWidget {
  const HolidayNudges({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nudges = ref.watch(holidayNudgesProvider).valueOrNull ?? const [];
    if (nudges.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [for (final n in nudges) _NudgeCard(nudge: n)],
    );
  }
}

class _NudgeCard extends ConsumerWidget {
  const _NudgeCard({required this.nudge});
  final HolidayNudge nudge;

  String get _when {
    if (nudge.daysAway == 0) return 'is today';
    if (nudge.daysAway == 1) return 'is tomorrow';
    return 'is in ${nudge.daysAway} days';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = festivalTheme(nudge.holiday.name);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      color: theme.color.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Text(theme.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${nudge.holiday.name} $_when',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Govt list: ${DateFormat('d MMM').format(nudge.date)}'
                    '${nudge.holiday.tentative ? ' (moon sighting)' : ''}'
                    ' — nothing planned yet.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _plan(context, ref),
              child: const Text('Plan it'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _plan(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final uuid = ref.read(uuidProvider);
    final now = DateTime.now();
    // Drop it on the gazette's date at 9am — a starting point the user can move
    // to the day they actually keep it.
    final start = DateTime(nudge.date.year, nudge.date.month, nudge.date.day, 9);
    await ref
        .read(taskServiceProvider)
        .create(
          TasksCompanion.insert(
            id: uuid.v4(),
            title: nudge.holiday.name,
            createdAt: now,
            updatedAt: now,
            scheduledStart: Value(start),
            kind: const Value(TaskKind.task),
          ),
        );
    ref.invalidate(holidayNudgesProvider);
    ref.invalidate(tasksForDayProvider(DateTime(start.year, start.month, start.day)));
    ref.invalidate(allTasksProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Added “${nudge.holiday.name}” on '
          '${DateFormat('d MMM').format(start)} — open it to make it yours.',
        ),
      ),
    );
  }
}
