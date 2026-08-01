import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../domain/holidays_india.dart';
import '../../domain/world_days.dart';
import '../areas/area_icons.dart' as ai;
import 'share_channels.dart';

/// A single area's tally for the day — name, colour, how many committed and how
/// many kept. Drives the by-area chips (front) and recap (back).
class AreaCount {
  const AreaCount(this.name, this.color, this.total, this.kept);
  final String name;
  final Color color;
  final int total;
  final int kept;
}

/// §13 One day, two faces. The **front** is the morning declaration and the
/// day's facts; the **back** is the close — what you honored and how you
/// restored. Facts are absolute; the world line is context; the declaration and
/// restoration are yours.
class DayCardData {
  const DayCardData({
    required this.day,
    required this.world,
    required this.declaration,
    required this.restoration,
    required this.closed,
    required this.areas,
    required this.heat,
    required this.total,
    required this.kept,
    required this.broken,
  });

  /// Build a card from the day's tasks and the user's areas, computing the
  /// by-area tallies and the timeline heatmap. Both the morning and evening
  /// share paths use this so the two faces always agree.
  factory DayCardData.compute({
    required DateTime day,
    required List<Task> tasks,
    required List<Area> areas,
    required bool closed,
    String? declaration,
    String? restoration,
  }) {
    final areaById = {for (final a in areas) a.id: a};
    final order = <String>[];
    final agg = <String, List<int>>{}; // key -> [total, kept]
    final names = <String, String>{};
    final colors = <String, Color>{};
    for (final t in tasks) {
      final a = t.areaId == null ? null : areaById[t.areaId];
      final key = a?.id ?? '_none';
      if (!agg.containsKey(key)) {
        agg[key] = [0, 0];
        order.add(key);
        names[key] = a?.displayName ?? 'Unfiled';
        colors[key] = ai.areaColor(a?.color) ?? const Color(0xFF9AA0A6);
      }
      agg[key]![0]++;
      if (t.status == TaskStatus.completed) agg[key]![1]++;
    }
    final areaCounts =
        order
            .map((k) => AreaCount(names[k]!, colors[k]!, agg[k]![0], agg[k]![1]))
            .toList()
          ..sort((a, b) => b.total.compareTo(a.total));

    // Timeline heatmap: 10 buckets across the waking day (6:00 → midnight).
    const buckets = 10;
    const startMin = 6 * 60;
    const span = 18 * 60;
    final heat = List<int>.filled(buckets, 0);
    for (final t in tasks) {
      final when = t.scheduledStart ?? t.dueDate;
      if (when == null) continue;
      final mins = when.hour * 60 + when.minute;
      var idx = ((mins - startMin) / (span / buckets)).floor();
      if (idx < 0) idx = 0;
      if (idx > buckets - 1) idx = buckets - 1;
      heat[idx]++;
    }

    final kept = tasks.where((t) => t.status == TaskStatus.completed).length;
    final broken = tasks
        .where(
          (t) =>
              t.status == TaskStatus.missed ||
              t.status == TaskStatus.cancelled,
        )
        .length;

    // Prefer a gazetted holiday for the world line (attributed), else a world
    // observance. The holiday is context the recipient will recognise.
    final holiday = holidayOn(day);
    final world = holiday != null
        ? WorldDay(holiday.name, 'A holiday, per the Govt of India list.')
        : worldDayFor(day);

    return DayCardData(
      day: day,
      world: world,
      declaration: declaration,
      restoration: restoration,
      closed: closed,
      areas: areaCounts,
      heat: heat,
      total: tasks.length,
      kept: kept,
      broken: broken,
    );
  }

  final DateTime day;
  final WorldDay? world;
  final String? declaration;
  final String? restoration;
  final bool closed;
  final List<AreaCount> areas;
  final List<int> heat;
  final int total;
  final int kept;
  final int broken;
}

class RitualCardScreen extends StatefulWidget {
  const RitualCardScreen({super.key, required this.data});
  final DayCardData data;

  @override
  State<RitualCardScreen> createState() => _RitualCardScreenState();
}

class _RitualCardScreenState extends State<RitualCardScreen> {
  final _captureKey = GlobalKey();
  bool _busy = false;

  DayCardData get _d => widget.data;

  Future<void> _shareCard() async {
    setState(() => _busy = true);
    try {
      final boundary =
          _captureKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw 'Could not render the card.';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/saara-day.png');
      await file.writeAsBytes(data.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)], text: _messageText());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not share: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareText() async {
    await shareTextViaChannels(
      context,
      text: _messageText(),
      subject: 'My day — via Saara',
    );
  }

  String _areaSummary() =>
      _d.areas.take(4).map((a) => '${a.name} ${a.total}').join(' · ');

  String _messageText() {
    final date = DateFormat('d MMMM yyyy').format(_d.day);
    final b = StringBuffer()..writeln('My day — $date')..writeln();
    if (_d.declaration != null && _d.declaration!.isNotEmpty) {
      b.writeln('🌅 Opening: “${_d.declaration}”');
    } else {
      b.writeln('🌅 Opening: ${_d.total} commitments today');
    }
    if (_d.areas.isNotEmpty) b.writeln('   ${_areaSummary()}');
    if (_d.world != null) b.writeln('🌍 The world today: ${_d.world!.title}');
    if (_d.closed) {
      b.writeln('🌙 Closing: Kept my word ${_d.kept} of ${_d.total}');
      if (_d.broken > 0) b.writeln('   Restoring ${_d.broken}');
      if (_d.restoration != null && _d.restoration!.isNotEmpty) {
        b.writeln('   “${_d.restoration}”');
      }
    }
    b
      ..writeln()
      ..writeln(
        "You're one of the people I've given my word to — thank you for being "
        'my mirror.',
      )
      ..writeln('— via Saara');
    return b.toString().trimRight();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share your day')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: _FlipCard(
                  front: _DayFace(data: _d, open: true),
                  back: _DayFace(data: _d, open: false),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap the card to flip — open on one side, close on the other.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share),
                label: const Text('Share card'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _busy ? null : _shareCard,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.notes),
                label: const Text('Share as text only'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _shareText,
              ),
              const SizedBox(height: 12),
              Text(
                'Shared as one image showing both faces — the close read with '
                'the morning it belongs to. Only what\'s on the card is shared; '
                'your task titles, notes and scores never are.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          // Off-screen capture target: both faces stacked into one image.
          Positioned(
            left: 0,
            top: 0,
            child: Transform.translate(
              offset: const Offset(-5000, 0),
              child: RepaintBoundary(
                key: _captureKey,
                child: _DayComposite(data: _d),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlipCard extends StatefulWidget {
  const _FlipCard({required this.front, required this.back});
  final Widget front;
  final Widget back;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_ctrl.isAnimating) return;
    _ctrl.value < 0.5 ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final angle = _ctrl.value * math.pi;
          final showFront = angle <= math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showFront
                ? widget.front
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: widget.back,
                  ),
          );
        },
      ),
    );
  }
}

/// Both faces stacked — the single shareable image.
class _DayComposite extends StatelessWidget {
  const _DayComposite({required this.data});
  final DayCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0E0E12),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DayFace(data: data, open: true),
          const SizedBox(height: 10),
          _DayFace(data: data, open: false),
        ],
      ),
    );
  }
}

/// One face of the day — sunrise for the open, dusk for the close.
class _DayFace extends StatelessWidget {
  const _DayFace({required this.data, required this.open});
  final DayCardData data;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final (top, bottom, ink, muted, accent) = open
        ? (
            const Color(0xFFF4A24C),
            const Color(0xFFCC5A2E),
            Colors.white,
            Colors.white70,
            Colors.white,
          )
        : (
            const Color(0xFF2B2E5B),
            const Color(0xFF15162B),
            const Color(0xFFF2ECE7),
            const Color(0xFFB9B4CC),
            const Color(0xFFE7C46B),
          );

    return Container(
      width: 380,
      height: 466,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -24,
            child: Icon(
              open ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              size: 160,
              color: accent.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      open
                          ? Icons.wb_twilight_rounded
                          : Icons.bedtime_rounded,
                      size: 15,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      open ? 'OPENING MY DAY' : 'CLOSING MY DAY',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('d MMM').format(data.day),
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...(open ? _front(ink, muted, accent) : _back(ink, muted)),
                const Spacer(),
                Divider(color: muted.withValues(alpha: 0.3), height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'SAARA',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Give your word. Keep it.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: muted,
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _label = TextStyle(
    fontSize: 9.5,
    letterSpacing: 1.8,
    fontWeight: FontWeight.w800,
  );

  List<Widget> _front(Color ink, Color muted, Color accent) {
    final decl = data.declaration?.trim();
    return [
      if (decl != null && decl.isNotEmpty) ...[
        Text('MY DECLARATION', style: _label.copyWith(color: muted)),
        const SizedBox(height: 5),
        Text(
          decl,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ink,
            fontSize: 20,
            height: 1.28,
            fontWeight: FontWeight.w500,
          ),
        ),
      ] else
        Text(
          data.total == 0
              ? 'A clear day ahead.'
              : '${data.total} commitment${data.total == 1 ? '' : 's'} today.',
          style: TextStyle(
            color: ink,
            fontSize: 26,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      if (data.world != null) ...[
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🌍', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.world!.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      data.world!.note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 16),
      Text(
        'TODAY · ${data.total} COMMITMENT${data.total == 1 ? '' : 'S'}',
        style: _label.copyWith(color: muted),
      ),
      if (data.areas.isNotEmpty) ...[
        const SizedBox(height: 7),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final a in data.areas.take(4)) _chip(a, ink),
          ],
        ),
      ],
      const SizedBox(height: 12),
      _heatmap(),
    ];
  }

  Widget _chip(AreaCount a, Color ink) => Container(
    padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: a.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '${a.name} ${a.total}',
          style: TextStyle(
            color: ink,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _heatmap() {
    final maxV = data.heat.fold<int>(0, math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            children: [
              for (var i = 0; i < data.heat.length; i++) ...[
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: maxV == 0
                            ? 0.12
                            : (data.heat[i] == 0
                                  ? 0.12
                                  : 0.28 + 0.62 * (data.heat[i] / maxV)),
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                if (i != data.heat.length - 1) const SizedBox(width: 3),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        DefaultTextStyle(
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9.5,
          ),
          child: const Row(
            children: [
              Text('6a'),
              Spacer(),
              Text('noon'),
              Spacer(),
              Text('6p'),
              Spacer(),
              Text('12a'),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _back(Color ink, Color muted) {
    if (!data.closed) {
      return [
        Text(
          'The day is still open.',
          style: TextStyle(
            color: ink,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "I'll close it tonight.",
          style: TextStyle(color: muted, fontSize: 15),
        ),
      ];
    }
    final byArea = data.areas
        .take(4)
        .map((a) => '${a.name} ${a.kept}/${a.total}')
        .join('  ·  ');
    return [
      Text('THE FACTS', style: _label.copyWith(color: muted)),
      const SizedBox(height: 5),
      Text(
        'Kept my word ${data.kept} of ${data.total}',
        style: TextStyle(
          color: ink,
          fontSize: 26,
          height: 1.15,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      if (byArea.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(byArea, style: TextStyle(color: muted, fontSize: 13)),
      ],
      if (data.broken > 0) ...[
        const SizedBox(height: 4),
        Text(
          'Restoring ${data.broken}',
          style: TextStyle(color: muted, fontSize: 13),
        ),
      ],
      if (data.restoration != null && data.restoration!.trim().isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(
          'ACKNOWLEDGE & RESTORE',
          style: _label.copyWith(color: const Color(0xFFE7C46B)),
        ),
        const SizedBox(height: 6),
        Text(
          '“${data.restoration!.trim()}”',
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ink,
            fontSize: 16,
            height: 1.34,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ];
  }
}
