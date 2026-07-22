import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../providers.dart';
import '../../services/google/meeting_note_tag.dart';

/// §4 hands-free agenda run — walks an event's action items one by one. The
/// current item is auto-started (ledger `started`), a live timer counts against
/// its planned duration, and completing it auto-starts the next. Built for
/// running a timed session (e.g. a 5-hour training) without fiddling per task.
class AgendaRunScreen extends ConsumerStatefulWidget {
  const AgendaRunScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });
  final String eventId;
  final String eventTitle;

  @override
  ConsumerState<AgendaRunScreen> createState() => _AgendaRunScreenState();
}

class _AgendaRunScreenState extends ConsumerState<AgendaRunScreen> {
  final List<Task> _agenda = [];
  int _index = 0;
  int _completed = 0;
  DateTime? _startedAt;
  Timer? _timer;
  bool _loading = true;
  bool _done = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final all = await ref
        .read(taskDaoProvider)
        .childTasksForEvent(widget.eventId);
    all.sort((a, b) {
      final sa = a.scheduledStart, sb = b.scheduledStart;
      if (sa == null && sb == null) return a.createdAt.compareTo(b.createdAt);
      if (sa == null) return 1;
      if (sb == null) return -1;
      return sa.compareTo(sb);
    });
    _agenda
      ..clear()
      ..addAll(
        all.where(
          (t) =>
              t.status != TaskStatus.completed &&
              t.status != TaskStatus.rejected,
        ),
      );
    if (_agenda.isEmpty) {
      setState(() {
        _loading = false;
        _done = true;
      });
      return;
    }
    await _startCurrent();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _startCurrent() async {
    final t = _agenda[_index];
    if (t.status == TaskStatus.created) {
      try {
        await ref.read(taskServiceProvider).start(t);
      } catch (_) {}
    }
    _startedAt = DateTime.now();
  }

  void _refreshLists() {
    ref.invalidate(childTasksForEventProvider(widget.eventId));
    ref.invalidate(childTaskCountsProvider);
    ref.invalidate(allTasksProvider);
    ref.invalidate(unscheduledTasksProvider);
    ref.invalidate(areaScoresProvider);
    ref.invalidate(overallEffectivenessProvider);
    final now = DateTime.now();
    ref.invalidate(tasksForDayProvider(DateTime(now.year, now.month, now.day)));
    ref.invalidate(tasksBetweenProvider); // calendar views
  }

  Future<void> _completeAndNext() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(taskServiceProvider).complete(_agenda[_index]);
      _completed++;
    } catch (_) {}
    _refreshLists();
    await _advance();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _skip() async {
    if (_busy) return;
    await _advance();
  }

  Future<void> _advance() async {
    if (_index < _agenda.length - 1) {
      setState(() => _index++);
      await _startCurrent();
    } else {
      _timer?.cancel();
      setState(() => _done = true);
    }
  }

  String _fmt(Duration d) {
    final neg = d.isNegative;
    d = d.abs();
    String two(int n) => n.toString().padLeft(2, '0');
    final base = d.inHours > 0
        ? '${d.inHours}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}'
        : '${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
    return neg ? '-$base' : base;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.eventTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _done
          ? _summary(context)
          : _runner(context),
    );
  }

  Widget _summary(BuildContext context) {
    final total = _agenda.length;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Agenda complete',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              total == 0
                  ? 'No open items to run.'
                  : 'You completed $_completed of $total item${total == 1 ? '' : 's'}.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _runner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = _agenda[_index];
    final fmt = DateFormat('h:mm a');
    final elapsed = _startedAt == null
        ? Duration.zero
        : DateTime.now().difference(_startedAt!);
    final dur = t.durationMin;
    final planned = dur == null ? null : Duration(minutes: dur);
    final over = planned != null && elapsed > planned;
    final accent = over ? scheme.error : scheme.primary;
    final remaining = planned == null ? null : planned - elapsed;
    final next = _index < _agenda.length - 1 ? _agenda[_index + 1] : null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Item ${_index + 1} of ${_agenda.length}',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(t.title, style: Theme.of(context).textTheme.headlineMedium),
          if (t.scheduledStart != null) ...[
            const SizedBox(height: 6),
            Text(
              planned == null
                  ? fmt.format(t.scheduledStart!)
                  : '${fmt.format(t.scheduledStart!)} – '
                        '${fmt.format(t.scheduledStart!.add(planned))} · ${dur}m',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const Spacer(),
          Center(
            child: Text(
              _fmt(elapsed),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (planned != null) ...[
            LinearProgressIndicator(
              value: (elapsed.inSeconds / planned.inSeconds).clamp(0.0, 1.0),
              minHeight: 10,
              color: accent,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                over
                    ? 'Over by ${_fmt(elapsed - planned)}'
                    : '${_fmt(remaining!)} left',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: over ? scheme.error : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          // Speaker notes for this segment — the reason to keep the runner open
          // while presenting (§7). Scrolls if long so the controls stay put.
          if ((t.notes?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 16),
            Flexible(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    stripMeetingLine(t.notes) ?? '',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
          ],
          const Spacer(),
          if (next != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Up next · ${next.title}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          FilledButton.icon(
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(next == null ? 'Complete & finish' : 'Complete & next'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _busy ? null : _completeAndNext,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Skip'),
                  onPressed: _busy ? null : _skip,
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('End session'),
                  onPressed: _busy
                      ? null
                      : () {
                          _timer?.cancel();
                          setState(() => _done = true);
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
