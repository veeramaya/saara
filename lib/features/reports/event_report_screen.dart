import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../domain/reliability.dart';
import '../../providers.dart';

/// §13 post-session report for an event that has an agenda: how each item was
/// *planned* vs how it actually *ran*, the session's own reliability, and —
/// when an AI key is configured — a short read on what to change next time.
///
/// Everything except the AI paragraph is computed deterministically from the
/// integrity ledger, so the numbers can't drift from what happened.
class EventReportScreen extends ConsumerStatefulWidget {
  const EventReportScreen({super.key, required this.eventId});
  final String eventId;

  @override
  ConsumerState<EventReportScreen> createState() => _EventReportScreenState();
}

/// One agenda line: what was planned, what actually happened, the gap.
class _Line {
  _Line(this.task);
  final Task task;

  Duration? get planned =>
      task.durationMin == null ? null : Duration(minutes: task.durationMin!);
  Duration? get actual => task.timeToCompleteMin == null
      ? null
      : Duration(minutes: task.timeToCompleteMin!);
  Duration? get variance =>
      (planned == null || actual == null) ? null : actual! - planned!;
  bool get done => task.status == TaskStatus.completed;
  bool get overran => (variance?.inMinutes ?? 0) > 0;
}

class _EventReportScreenState extends ConsumerState<EventReportScreen> {
  String? _aiInsight;
  bool _aiBusy = false;
  String? _aiError;

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(taskByIdProvider(widget.eventId));
    final itemsAsync = ref.watch(childTasksForEventProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Share report',
            onPressed: () {
              final e = eventAsync.valueOrNull;
              final i = itemsAsync.valueOrNull;
              if (e != null && i != null) Share.share(_plainText(e, _lines(i)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export as file',
            onPressed: () {
              final e = eventAsync.valueOrNull;
              final i = itemsAsync.valueOrNull;
              if (e != null && i != null) _exportFile(e, _lines(i));
            },
          ),
        ],
      ),
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (event) {
          if (event == null) return const Center(child: Text('Not found.'));
          return itemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (items) => _body(context, event, _lines(items)),
          );
        },
      ),
    );
  }

  List<_Line> _lines(List<Task> items) {
    final sorted = [...items]
      ..sort((a, b) {
        final sa = a.scheduledStart, sb = b.scheduledStart;
        if (sa == null && sb == null) return a.createdAt.compareTo(b.createdAt);
        if (sa == null) return 1;
        if (sb == null) return -1;
        return sa.compareTo(sb);
      });
    return [for (final t in sorted) _Line(t)];
  }

  Widget _body(BuildContext context, Task event, List<_Line> lines) {
    final scheme = Theme.of(context).colorScheme;
    final when = event.scheduledStart ?? event.dueDate;
    final done = lines.where((l) => l.done).length;
    final pct = lines.isEmpty ? 0.0 : done / lines.length * 100;
    final plannedTotal = lines.fold<int>(
      0,
      (a, l) => a + (l.planned?.inMinutes ?? 0),
    );
    final actualTotal = lines.fold<int>(
      0,
      (a, l) => a + (l.actual?.inMinutes ?? 0),
    );
    final measured = lines.where((l) => l.variance != null).toList();
    final overran = measured.where((l) => l.overran).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(event.title, style: Theme.of(context).textTheme.headlineSmall),
        if (when != null)
          Text(
            DateFormat('EEEE, MMM d · h:mm a').format(when),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        const SizedBox(height: 16),

        // ── headline numbers ────────────────────────────────────────────────
        Row(
          children: [
            _Stat(label: 'Completed', value: '$done/${lines.length}'),
            _Stat(
              label: 'Session score',
              value: '${pct.round()}%',
              sub: reliabilityLevelName(pct),
            ),
            if (plannedTotal > 0)
              _Stat(
                label: 'Planned',
                value: _hm(plannedTotal),
                sub: actualTotal > 0 ? 'ran ${_hm(actualTotal)}' : null,
              ),
          ],
        ),
        const Divider(height: 32),

        Text('Plan vs actual', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Actual time comes from the integrity ledger — when you started '
          'and completed each item.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (lines.isEmpty)
          const Text('No action items on this event.')
        else
          for (final l in lines) _lineTile(context, l),

        const Divider(height: 32),
        Text(
          'What the numbers say',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final s in _observations(
          lines,
          overran,
          plannedTotal,
          actualTotal,
          done,
          pct,
        ))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 7, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(s)),
              ],
            ),
          ),

        const Divider(height: 32),
        Row(
          children: [
            Text(
              'Saara insights',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton.icon(
              icon: _aiBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(_aiInsight == null ? 'Generate' : 'Regenerate'),
              onPressed: _aiBusy ? null : () => _generate(event, lines),
            ),
          ],
        ),
        if (_aiError != null)
          Text(_aiError!, style: TextStyle(color: scheme.error)),
        if (_aiInsight != null)
          Card(
            color: scheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_aiInsight!),
            ),
          )
        else if (_aiError == null && !_aiBusy)
          Text(
            'Uses your own AI key to read the timings above and suggest what to '
            'tighten next time. Nothing is sent unless you tap Generate.',
            style: Theme.of(context).textTheme.bodySmall,
          ),

        if ((event.reviewNotes?.trim().isNotEmpty ?? false)) ...[
          const Divider(height: 32),
          Text('Your review', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(event.reviewNotes!),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _lineTile(BuildContext context, _Line l) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = DateFormat('h:mm a');
    final start = l.task.scheduledStart;
    final v = l.variance;
    final vText = v == null
        ? null
        : (v.inMinutes == 0
              ? 'on time'
              : '${v.isNegative ? '−' : '+'}${v.abs().inMinutes}m');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            l.done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: l.done ? Colors.green : scheme.outline,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  [
                    if (start != null) fmt.format(start),
                    if (l.planned != null) 'planned ${l.planned!.inMinutes}m',
                    if (l.actual != null) 'took ${l.actual!.inMinutes}m',
                    if (!l.done) l.task.status.name,
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (vText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: l.overran
                    ? scheme.errorContainer
                    : scheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                vText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: l.overran
                      ? scheme.onErrorContainer
                      : scheme.onPrimaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Deterministic read of the session — always available, no AI key needed.
  List<String> _observations(
    List<_Line> lines,
    List<_Line> overran,
    int plannedTotal,
    int actualTotal,
    int done,
    double pct,
  ) {
    final out = <String>[];
    if (lines.isEmpty) return out;

    out.add(
      'You kept $done of ${lines.length} commitments — '
      '${pct.round()}%, ${reliabilityLevelName(pct)} for this session.',
    );

    if (plannedTotal > 0 && actualTotal > 0) {
      final diff = actualTotal - plannedTotal;
      out.add(
        diff == 0
            ? 'You ran exactly to plan (${_hm(plannedTotal)}).'
            : diff > 0
            ? 'The session ran ${_hm(diff)} over its ${_hm(plannedTotal)} plan.'
            : 'You finished ${_hm(-diff)} inside the ${_hm(plannedTotal)} plan.',
      );
    }

    if (overran.isNotEmpty) {
      final worst = overran.reduce(
        (a, b) => (a.variance!.inMinutes >= b.variance!.inMinutes) ? a : b,
      );
      out.add(
        '${overran.length} item${overran.length == 1 ? '' : 's'} ran long; '
        'the biggest was “${worst.task.title}” at '
        '+${worst.variance!.inMinutes}m.',
      );
    }

    final unstarted = lines.where((l) => !l.done).toList();
    if (unstarted.isNotEmpty) {
      out.add(
        'Still open: ${unstarted.map((l) => l.task.title).take(3).join(', ')}'
        '${unstarted.length > 3 ? ' and ${unstarted.length - 3} more' : ''}.',
      );
    }
    return out;
  }

  Future<void> _generate(Task event, List<_Line> lines) async {
    setState(() {
      _aiBusy = true;
      _aiError = null;
    });
    try {
      final config = await ref.read(aiConfigProvider.future);
      if (!config.isConfigured) {
        setState(
          () => _aiError =
              'Add an AI key in Settings → Saara AI to generate insights.',
        );
        return;
      }
      final rows = lines
          .map(
            (l) =>
                '- ${l.task.title}: planned '
                '${l.planned?.inMinutes ?? '?'}m, took '
                '${l.actual?.inMinutes ?? 'n/a'}m, ${l.task.status.name}',
          )
          .join('\n');
      final prompt =
          'You are Saara, a calm integrity coach. Below is how a session ran: '
          'each agenda item with its planned duration, actual duration, and '
          'status.\n\nSESSION: ${event.title}\n$rows\n\n'
          'In under 120 words, give the facilitator: (1) two specific '
          'observations about pacing or follow-through, and (2) two concrete '
          'changes for next time. Be direct and practical, reference the actual '
          'item names, and do not invent data. Plain prose, no headings.';
      final res = await ref
          .read(llmServiceProvider)
          .extractFromTextHealing(config, prompt: prompt);
      if (res.usedModel != null && config.apiKey != null) {
        await ref
            .read(aiConfigStoreProvider)
            .save(
              provider: config.provider,
              apiKey: config.apiKey!,
              model: res.usedModel!,
            );
        ref.invalidate(aiConfigProvider);
      }
      if (mounted) setState(() => _aiInsight = res.text.trim());
    } catch (e) {
      if (mounted) setState(() => _aiError = '$e');
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  /// §1.1 export the event **with its whole agenda** as a Markdown file the
  /// user keeps — readable anywhere, and re-importable by Saara's own `.md`
  /// import (headings become areas, `- task` lines become tasks).
  Future<void> _exportFile(Task event, List<_Line> lines) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final when = event.scheduledStart ?? event.dueDate;
      final done = lines.where((l) => l.done).length;
      final pct = lines.isEmpty ? 0.0 : done / lines.length * 100;
      final fmt = DateFormat('h:mm a');

      final b = StringBuffer()
        ..writeln('# ${event.title}')
        ..writeln();
      if (when != null) {
        b.writeln(
          '**When:** ${DateFormat('EEEE, d MMMM yyyy · h:mm a').format(when)}',
        );
      }
      if ((event.locationName ?? '').trim().isNotEmpty) {
        b.writeln('**Where:** ${event.locationName}');
      }
      b
        ..writeln(
          '**Kept:** $done of ${lines.length} '
          '(${pct.round()}% · ${reliabilityLevelName(pct)})',
        )
        ..writeln()
        ..writeln('## Agenda')
        ..writeln();

      for (final l in lines) {
        final s = l.task.scheduledStart;
        final slot = s == null
            ? ''
            : (l.planned == null
                  ? '${fmt.format(s)} — '
                  : '${fmt.format(s)}–${fmt.format(s.add(l.planned!))} — ');
        final v = l.variance;
        final actual = l.actual == null
            ? ''
            : ' _(took ${l.actual!.inMinutes}m'
                  '${v == null || v.inMinutes == 0 ? '' : ', ${v.isNegative ? '' : '+'}${v.inMinutes}m'})_';
        b.writeln('- [${l.done ? 'x' : ' '}] $slot${l.task.title}$actual');
        final notes = l.task.notes?.trim();
        if (notes != null && notes.isNotEmpty) {
          for (final line in notes.split('\n')) {
            b.writeln('    > $line');
          }
        }
      }

      if (_aiInsight != null) {
        b
          ..writeln()
          ..writeln('## Saara insights')
          ..writeln()
          ..writeln(_aiInsight);
      }
      if ((event.reviewNotes ?? '').trim().isNotEmpty) {
        b
          ..writeln()
          ..writeln('## Review')
          ..writeln()
          ..writeln(event.reviewNotes);
      }
      b
        ..writeln()
        ..writeln('---')
        ..writeln('_Exported from Saara_');

      final dir = await getTemporaryDirectory();
      final safe = event.title
          .replaceAll(RegExp(r'[^A-Za-z0-9 ]'), '')
          .trim()
          .replaceAll(' ', '-');
      final stamp = when == null
          ? ''
          : '-${DateFormat('yyyy-MM-dd').format(when)}';
      final file = File('${dir.path}/$safe$stamp.md');
      await file.writeAsString(b.toString());
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: '${event.title} — agenda & report');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  String _plainText(Task event, List<_Line> lines) {
    final when = event.scheduledStart ?? event.dueDate;
    final done = lines.where((l) => l.done).length;
    final pct = lines.isEmpty ? 0.0 : done / lines.length * 100;
    final b = StringBuffer()
      ..writeln(event.title)
      ..writeln(
        when == null ? '' : DateFormat('EEEE, MMM d · h:mm a').format(when),
      )
      ..writeln()
      ..writeln(
        'Completed $done/${lines.length} · ${pct.round()}% · '
        '${reliabilityLevelName(pct)}',
      )
      ..writeln();
    for (final l in lines) {
      final v = l.variance;
      b.writeln(
        '${l.done ? '[x]' : '[ ]'} ${l.task.title}'
        '${l.planned == null ? '' : ' — planned ${l.planned!.inMinutes}m'}'
        '${l.actual == null ? '' : ', took ${l.actual!.inMinutes}m'}'
        '${v == null || v.inMinutes == 0 ? '' : ' (${v.isNegative ? '−' : '+'}${v.abs().inMinutes}m)'}',
      );
    }
    if (_aiInsight != null) {
      b
        ..writeln()
        ..writeln(_aiInsight);
    }
    if (event.reviewNotes?.trim().isNotEmpty ?? false) {
      b
        ..writeln()
        ..writeln('Review:')
        ..writeln(event.reviewNotes);
    }
    b
      ..writeln()
      ..writeln('— via Saara');
    return b.toString();
  }

  static String _hm(int minutes) {
    final h = minutes ~/ 60, m = minutes % 60;
    if (h == 0) return '${m}m';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.sub});
  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (sub != null)
            Text(sub!, style: TextStyle(fontSize: 12, color: scheme.primary)),
        ],
      ),
    );
  }
}
