import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/platform.dart';
import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../domain/festival_theme.dart';
import '../../domain/holidays_india.dart';
import '../../domain/world_days.dart';
import '../../providers.dart';
import '../areas/area_icons.dart' as ai;
import '../settings/lan_sync_screen.dart';
import 'share_card_deck.dart';
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
    required this.isHoliday,
    required this.capturedAt,
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
      isHoliday: holiday != null,
      capturedAt: DateTime.now(),
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

  /// True when the day is a gazetted holiday — the card takes on a light
  /// festival accent.
  final bool isHoliday;

  /// The instant the facts were captured. The card is an honest point-in-time
  /// snapshot: it counts **all** the day's tasks as they stood at this moment,
  /// and says so — add more later and a fresh card carries a fresh stamp. This
  /// is the integrity guard against a card drifting from the day it depicts.
  final DateTime capturedAt;
}

class RitualCardScreen extends ConsumerStatefulWidget {
  const RitualCardScreen({super.key, required this.data});
  final DayCardData data;

  @override
  ConsumerState<RitualCardScreen> createState() => _RitualCardScreenState();
}

class _RitualCardScreenState extends ConsumerState<RitualCardScreen> {
  final _captureKey = GlobalKey();
  final PageController _pager = PageController();
  int _page = 0;
  bool _busy = false;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  /// When a card was last shared for this day (from any device) — so we can say
  /// "you already shared one — revise?" instead of silently duplicating.
  DateTime? _alreadySharedAt;

  DayCardData get _d => widget.data;

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_d.day);

  @override
  void initState() {
    super.initState();
    _loadSharedStamp();
  }

  Future<void> _loadSharedStamp() async {
    final log = await ref.read(appDatabaseProvider).dayLogFor(_dateKey);
    if (mounted) setState(() => _alreadySharedAt = log?.cardSharedAt);
  }

  Future<void> _stampShared() async {
    await ref.read(appDatabaseProvider).markCardShared(_dateKey);
    if (mounted) setState(() => _alreadySharedAt = DateTime.now());
  }

  Future<void> _shareCard() async {
    setState(() => _busy = true);
    try {
      await shareOrSaveCardImage(
        context,
        captureKey: _captureKey,
        text: _messageText(),
        fileBase: 'saara-day',
      );
      await _stampShared();
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
      subject: 'My day',
    );
    await _stampShared();
  }

  String _areaSummary() =>
      _d.areas.take(4).map((a) => '${a.name} ${a.total}').join(' · ');

  String _messageText() {
    final date = DateFormat('d MMMM yyyy').format(_d.day);
    final stamp = DateFormat('h:mm a').format(_d.capturedAt);
    final b = StringBuffer()
      ..writeln('My day — $date (as of $stamp)')
      ..writeln();
    if (_d.declaration != null && _d.declaration!.isNotEmpty) {
      b.writeln('🌅 Declaration: “${_d.declaration}”');
    } else {
      b.writeln('🌅 ${_d.total} commitment${_d.total == 1 ? '' : 's'} for today');
    }
    if (_d.areas.isNotEmpty) b.writeln('   Tasks by area — ${_areaSummary()}');
    if (_d.world != null) b.writeln('🌍 The world today: ${_d.world!.title}');
    if (_d.closed) {
      b.writeln('🌙 Closing: kept my word ${_d.kept} of ${_d.total}');
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
      );
    return b.toString().trimRight();
  }

  /// So the user knows whether this card is the current, shared truth before
  /// they send it: amber when this device has edits the others don't have yet,
  /// a quiet green confirmation when everything's in sync.
  Widget _freshnessNote() {
    final fresh = ref.watch(syncFreshnessProvider).valueOrNull;
    if (fresh == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    if (fresh.unsynced) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.sync_problem,
              size: 18,
              color: scheme.onTertiaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "This device has changes your other devices don't have yet. "
                'Sync first so this card is the shared truth.',
                style: TextStyle(
                  color: scheme.onTertiaryContainer,
                  fontSize: 12.5,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LanSyncScreen()),
              ),
              child: const Text('Sync'),
            ),
          ],
        ),
      );
    }
    final last = fresh.lastSync;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 15, color: Colors.green.shade600),
          const SizedBox(width: 6),
          Text(
            last == null
                ? 'This device is up to date.'
                : 'Up to date · last synced '
                      '${DateFormat('MMM d, h:mm a').format(last)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// "You already shared a card today — revise?" so a second share reads as a
  /// deliberate update, not a duplicate. Reflects a share from any device.
  Widget _alreadySharedNote() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.history, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You already shared a card for this day at '
              '${DateFormat('h:mm a').format(_alreadySharedAt!)}. '
              'Sharing again sends an updated one.',
              style: TextStyle(
                fontSize: 12.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share your day')),
      body: Stack(
        children: [
          ListView(
            // Add the bottom system inset so the last button clears the
            // Android 15 edge-to-edge gesture bar (no bottomNavigationBar here).
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              _freshnessNote(),
              if (_alreadySharedAt != null) _alreadySharedNote(),
              Center(
                child: PagedViewer(
                  controller: _pager,
                  page: _page,
                  onPageChanged: (i) => setState(() => _page = i),
                  dotColor: Theme.of(context).colorScheme.primary,
                  pageWidth: 380,
                  pageHeight: 466,
                  pages: [
                    _DayFace(data: _d, open: true),
                    _DayFace(data: _d, open: false),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Swipe or tap the card — open on one side, close on the '
                  'other. Shared as one image showing both.',
                  textAlign: TextAlign.center,
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
                    : Icon(isDesktop ? Icons.download : Icons.ios_share),
                label: Text(isDesktop ? 'Save card' : 'Share card'),
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
                isDesktop
                    ? 'One image showing both faces — the close read with the '
                          'morning it belongs to. It saves to your Downloads so '
                          'you can attach it in WhatsApp or mail. Only what\'s on '
                          'the card leaves the device.'
                    : 'One image showing both faces — the close read with the '
                          'morning it belongs to. Only what\'s on the card is '
                          'shared; your task titles, notes and scores never are.',
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
                child: ReportComposite(
                  style: CardStyle.dark,
                  pages: [
                    _DayFace(data: _d, open: true),
                    _DayFace(data: _d, open: false),
                  ],
                ),
              ),
            ),
          ),
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
                    if (data.isHoliday && data.world != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          festivalTheme(data.world!.title).emoji,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '${DateFormat('d MMM').format(data.day)}  ·  '
                      'as of ${DateFormat('h:mm a').format(data.capturedAt)}',
                      style: TextStyle(color: muted, fontSize: 10.5),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...(open ? _front(ink, muted, accent) : _back(ink, muted)),
                const Spacer(),
                Divider(color: muted.withValues(alpha: 0.3), height: 1),
                const SizedBox(height: 10),
                Text(
                  'Give your word. Keep it.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
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
              Text(
                data.isHoliday
                    ? festivalTheme(data.world!.title).emoji
                    : '🌍',
                style: const TextStyle(fontSize: 15),
              ),
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
