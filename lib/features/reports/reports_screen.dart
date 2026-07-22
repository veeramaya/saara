import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/reliability.dart';
import '../../domain/report.dart';
import '../../providers.dart';
import '../listeners/listeners_screen.dart' show listenerGapSuggestion;
import 'integrity_wheel.dart';

/// Performance dashboard (§13) — daily/weekly/monthly kept-word counts and the
/// current streak, all computed deterministically from the integrity ledger.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reportSummaryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(reportSummaryProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (r) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Integrity across areas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a wedge to drill into that area.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            const IntegrityWheel(),
            const SizedBox(height: 16),
            _ReliabilityByScaleCard(summary: r),
            const _ListenerGapCard(),
            const _SaaraValueCard(),
            const SizedBox(height: 8),
            _StreakCard(streak: r.streakDays),
            const SizedBox(height: 16),
            _RateCard(rate: r.weekCompletionRate),
            const SizedBox(height: 16),
            Text(
              'Kept-word counts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _StatRow(label: 'Completed today', value: r.todayCompleted),
            _StatRow(label: 'Completed this week', value: r.weekCompleted),
            _StatRow(
              label: 'Missed this week',
              value: r.weekMissed,
              warn: true,
            ),
            _StatRow(label: 'Rejected this week', value: r.weekRejected),
            const Divider(height: 24),
            _StatRow(label: 'Completed this month', value: r.monthCompleted),
            _StatRow(
              label: 'Missed this month',
              value: r.monthMissed,
              warn: true,
            ),
            const SizedBox(height: 24),
            Text(
              'Computed from the integrity ledger — every completion, miss, and '
              'rejection is recorded, so these numbers can\'t drift from what '
              'actually happened.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Reliability placed on the ladder **per time scale** (§13). The same word
/// kept today weighs less against a week's or month's commitments, so a strong
/// day can sit inside a middling week — exactly what the ladder should show.
class _ReliabilityByScaleCard extends StatelessWidget {
  const _ReliabilityByScaleCard({required this.summary});
  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reliability over time',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Kept ÷ committed, on the ladder — for each window.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _ScaleRow(
              label: 'Today',
              pct: summary.todayEffectiveness,
              committed: summary.todayCommitted,
            ),
            _ScaleRow(
              label: 'This week',
              pct: summary.weekEffectiveness,
              committed: summary.weekCommitted,
            ),
            _ScaleRow(
              label: 'This month',
              pct: summary.monthEffectiveness,
              committed: summary.monthCommitted,
            ),
            _ScaleRow(
              label: 'All-time',
              pct: summary.allEffectiveness,
              committed: summary.allCommitted,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleRow extends StatelessWidget {
  const _ScaleRow({
    required this.label,
    required this.pct,
    required this.committed,
  });
  final String label;
  final double pct;
  final int committed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasData = committed > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: hasData
                ? Row(
                    children: [
                      Text(
                        '${pct.round()}%',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· $committed committed',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  )
                : Text(
                    'No commitments yet',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
          ),
          if (hasData)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                reliabilityLevelName(pct),
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// What your committed listeners see, beside your own score (§13).
class _ListenerGapCard extends ConsumerWidget {
  const _ListenerGapCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fb = ref.watch(latestListenerFeedbackProvider);
    final selfAsync = ref.watch(overallEffectivenessProvider);
    return fb.maybeWhen(
      data: (f) {
        if (f == null) return const SizedBox.shrink();
        final self = selfAsync.maybeWhen(data: (v) => v, orElse: () => 0.0);
        final scheme = Theme.of(context).colorScheme;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What your listeners see',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Pair(label: 'You', pct: self.round()),
                    const Icon(Icons.compare_arrows),
                    _Pair(label: 'Listener', pct: f.ratingPct),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.tips_and_updates_outlined,
                      size: 16,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        listenerGapSuggestion(self, f.ratingPct),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair({required this.label, required this.pct});
  final String label;
  final int pct;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: scheme.onSurfaceVariant,
          ),
        ),
        Text(
          '$pct%',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          reliabilityLevelName(pct.toDouble()),
          style: TextStyle(fontSize: 11, color: scheme.primary),
        ),
      ],
    );
  }
}

/// The "Value by Saara" tally (§13) — what the platform delivered.
class _SaaraValueCard extends ConsumerWidget {
  const _SaaraValueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(saaraValueProvider);
    return async.maybeWhen(
      data: (pts) {
        if (pts <= 0) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        return Card(
          color: scheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Value by Saara',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$pts pts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              size: 40,
              color: scheme.onPrimaryContainer,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak day${streak == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'current streak',
                  style: TextStyle(color: scheme.onPrimaryContainer),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({required this.rate});
  final double rate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This week — kept your word',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: rate,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(rate * 100).round()}%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, this.warn = false});
  final String label;
  final int value;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: warn && value > 0
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
