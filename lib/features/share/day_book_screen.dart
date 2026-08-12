import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/platform.dart';
import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../providers.dart';
import '../common/task_status_icon.dart';
import 'flipbook_html.dart';
import 'report_card.dart';
import 'ritual_card_screen.dart';
import 'share_card_deck.dart';

/// §13 The **share book** — a filtered album of cards for a specific audience.
/// You choose *what* to cover (day cards, task cards, event cards), the *tense*
/// (a report of what happened, or an invitation to what's coming), the *scope*
/// (an area, a date range, which outcomes), and *which fields* each card shows.
/// The result is one self-contained HTML flipbook a committed listener can open
/// in any browser — nothing uploaded, works offline. One methodology, so you
/// can share exactly what you mean to whom you mean.
class DayBookScreen extends ConsumerStatefulWidget {
  const DayBookScreen({super.key});

  @override
  ConsumerState<DayBookScreen> createState() => _DayBookScreenState();
}

/// A report (what happened) vs an invitation (what's coming).
enum _Tense { report, invitation }

/// What kinds of card the book gathers.
enum _Content { days, tasks, events }

/// Which fields a card shows — options that travel across the whole book.
enum _CardField { when, status, outcome, join, location }

class _DayBookScreenState extends ConsumerState<DayBookScreen> {
  final PageController _pager = PageController();
  int _page = 0;
  bool _loading = true;
  bool _busy = false;

  // --- filters (what to share) ---
  _Tense _tense = _Tense.report;
  int _days = 7;
  final Set<_Content> _content = {_Content.days, _Content.tasks, _Content.events};
  String? _areaId; // null = all areas
  final Set<TaskStatus> _statuses = {TaskStatus.completed};
  final Set<_CardField> _fields = {
    _CardField.when,
    _CardField.status,
    _CardField.outcome,
    _CardField.join,
    _CardField.location,
  };

  // --- gathered data ---
  List<Area> _areas = const [];
  List<DayCardData> _cards = const [];
  List<({Task task, Area? area})> _items = const [];
  List<GlobalKey> _keys = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  bool _on(_CardField f) => _fields.contains(f);

  Future<void> _load() async {
    setState(() => _loading = true);
    final dao = ref.read(taskDaoProvider);
    final db = ref.read(appDatabaseProvider);
    final areas = await ref.read(activeAreasProvider.future);
    final areaById = {for (final a in areas) a.id: a};
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    final isReport = _tense == _Tense.report;

    final cards = <DayCardData>[];
    final items = <({Task task, Area? area})>[];
    final seen = <String>{};

    for (var d = 0; d < _days; d++) {
      // Report looks back; invitation looks ahead.
      final day = isReport
          ? base.subtract(Duration(days: d))
          : base.add(Duration(days: d));
      final tasks = await dao.tasksForDay(day);
      final log = isReport
          ? await db.dayLogFor(DateFormat('yyyy-MM-dd').format(day))
          : null;

      // Day cards: report tense, "Days" selected, and no area filter (a day
      // card is whole-day, not area-scoped).
      if (isReport &&
          _content.contains(_Content.days) &&
          _areaId == null &&
          (tasks.isNotEmpty || log != null)) {
        cards.add(
          DayCardData.compute(
            day: day,
            tasks: tasks,
            areas: areas,
            closed: log?.closedAt != null,
            declaration: log?.declaration,
            restoration: log?.reflection,
          ),
        );
      }

      for (final t in tasks) {
        if (_areaId != null && t.areaId != _areaId) continue;
        final isEvent = t.kind == TaskKind.event;
        if (isEvent && !_content.contains(_Content.events)) continue;
        if (!isEvent && !_content.contains(_Content.tasks)) continue;
        if (isReport) {
          if (!_statuses.contains(t.status)) continue;
        } else {
          // An invitation is for something still ahead of you.
          if (taskStatusClosed(t.status)) continue;
        }
        if (!seen.add(t.id)) continue;
        items.add((
          task: t,
          area: t.areaId == null ? null : areaById[t.areaId],
        ));
      }
    }

    if (!mounted) return;
    setState(() {
      _areas = areas;
      _cards = cards;
      _items = items;
      _keys = [for (var i = 0; i < cards.length * 2 + items.length; i++) GlobalKey()];
      _page = 0;
      _loading = false;
    });
  }

  List<({Widget page, String caption})> _pages() {
    final out = <({Widget page, String caption})>[];
    for (final c in _cards) {
      final label = DateFormat('EEE, d MMM').format(c.day);
      out.add((page: DayFace(data: c, open: true), caption: '$label — open'));
      out.add((page: DayFace(data: c, open: false), caption: '$label — close'));
    }
    for (final it in _items) {
      final p = CardPalette.of(CardStyle.brand, it.area?.color, it.area?.icon);
      final card = _tense == _Tense.report
          ? reportSummaryCard(
              task: it.task,
              palette: p,
              areaName: it.area?.displayName,
              showWhen: _on(_CardField.when),
              showStatus: _on(_CardField.status),
              showOutcome: _on(_CardField.outcome),
            )
          : invitationSummaryCard(
              task: it.task,
              palette: p,
              areaName: it.area?.displayName,
              showWhen: _on(_CardField.when),
              showJoin: _on(_CardField.join),
              showLocation: _on(_CardField.location),
            );
      out.add((
        page: _box(card),
        caption:
            '${_tense == _Tense.report ? 'Report' : 'Invite'} — ${it.task.title}',
      ));
    }
    return out;
  }

  Widget _box(Widget card) =>
      SizedBox(width: 380, height: 466, child: Center(child: card));

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      final meta = _pages();
      final pages = <Uint8List>[];
      final captions = <String>[];
      for (var i = 0; i < meta.length && i < _keys.length; i++) {
        final png = await capturePng(_keys[i], pixelRatio: 2);
        if (png == null) continue;
        pages.add(png);
        captions.add(meta[i].caption);
      }
      if (pages.isEmpty) throw 'Nothing matches these filters yet.';
      final html = buildFlipbookHtml(
        title: _bookTitle(),
        pages: pages,
        captions: captions,
      );
      if (!mounted) return;
      await shareOrSaveBytes(
        context,
        bytes: utf8.encode(html),
        fileName: 'saara-book.html',
        shareText: _bookTitle(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not build the book: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _bookTitle() {
    final area = _areaId == null
        ? null
        : _areas.where((a) => a.id == _areaId).firstOrNull?.displayName;
    final what = _tense == _Tense.report ? 'report' : 'invitations';
    return area == null ? 'My $what' : '$area — $what';
  }

  // Reload for filters that change *which* cards; field toggles just repaint.
  void _reload(VoidCallback change) {
    setState(change);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share book')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _body(),
    );
  }

  Widget _body() {
    final pages = _pages();
    final capturePages = _pages();
    final has = pages.isNotEmpty;
    if (_page >= pages.length) _page = 0;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            if (has) ...[
              Center(
                child: PagedViewer(
                  controller: _pager,
                  page: _page,
                  onPageChanged: (i) => setState(() => _page = i),
                  dotColor: Theme.of(context).colorScheme.primary,
                  pageWidth: 380,
                  pageHeight: 466,
                  pages: [for (final e in pages) e.page],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${_cards.length} day${_cards.length == 1 ? '' : 's'} · '
                  '${_items.length} '
                  '${_tense == _Tense.report ? 'report' : 'invite'}'
                  '${_items.length == 1 ? '' : 's'} · ${pages.length} pages',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'Nothing matches these filters. Widen the range, add a '
                  'content type, or pick a different area.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 16),
            const Divider(),
            _filters(),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(isDesktop ? Icons.download : Icons.ios_share),
              label: Text(isDesktop ? 'Save book (HTML)' : 'Share book (HTML)'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: (_busy || !has) ? null : _export,
            ),
            const SizedBox(height: 12),
            Text(
              'The book is one self-contained web page — every card embedded as '
              'an image. It opens in any browser, works offline, and nothing is '
              'uploaded. Send it to the right listener over WhatsApp or mail.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        // Off-screen capture targets: one page per key.
        Positioned(
          left: 0,
          top: 0,
          child: Transform.translate(
            offset: const Offset(-5000, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < capturePages.length && i < _keys.length; i++)
                  RepaintBoundary(key: _keys[i], child: capturePages[i].page),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _filters() {
    final isReport = _tense == _Tense.report;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Type of share'),
        SegmentedButton<_Tense>(
          segments: const [
            ButtonSegment(
              value: _Tense.report,
              icon: Icon(Icons.assignment_turned_in_outlined, size: 18),
              label: Text('Report'),
            ),
            ButtonSegment(
              value: _Tense.invitation,
              icon: Icon(Icons.mail_outline, size: 18),
              label: Text('Invitation'),
            ),
          ],
          selected: {_tense},
          onSelectionChanged: (s) => _reload(() {
            _tense = s.first;
            if (_tense == _Tense.invitation) {
              _content.remove(_Content.days);
            } else {
              _content.add(_Content.days);
            }
          }),
        ),
        const SizedBox(height: 14),
        _label(isReport ? 'Last' : 'Next'),
        Wrap(
          spacing: 8,
          children: [
            for (final n in const [7, 14, 30, 90])
              ChoiceChip(
                label: Text('$n days'),
                selected: _days == n,
                onSelected: (_) => _reload(() => _days = n),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _label('Cover'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (isReport)
              _contentChip(_Content.days, 'Day cards', enabled: _areaId == null),
            _contentChip(_Content.tasks, 'Tasks'),
            _contentChip(_Content.events, 'Events'),
          ],
        ),
        const SizedBox(height: 14),
        _label('Area'),
        DropdownButton<String?>(
          value: _areaId,
          isExpanded: true,
          items: [
            const DropdownMenuItem(value: null, child: Text('All areas')),
            for (final a in _areas)
              DropdownMenuItem(value: a.id, child: Text(a.displayName)),
          ],
          onChanged: (v) => _reload(() => _areaId = v),
        ),
        if (isReport) ...[
          const SizedBox(height: 8),
          _label('Outcomes'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _statusChip(TaskStatus.completed, 'Completed'),
              _statusChip(TaskStatus.missed, 'Missed'),
              _statusChip(TaskStatus.cancelled, 'Fell short'),
            ],
          ),
        ],
        const SizedBox(height: 14),
        _label('Show on each card'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: isReport
              ? [
                  _fieldChip(_CardField.when, 'Date & time'),
                  _fieldChip(_CardField.status, 'Status'),
                  _fieldChip(_CardField.outcome, 'Outcome'),
                ]
              : [
                  _fieldChip(_CardField.when, 'Date & time'),
                  _fieldChip(_CardField.join, 'Join link'),
                  _fieldChip(_CardField.location, 'Location'),
                ],
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge),
  );

  Widget _contentChip(_Content c, String label, {bool enabled = true}) =>
      FilterChip(
        label: Text(label),
        selected: _content.contains(c),
        onSelected: enabled
            ? (v) => _reload(() => v ? _content.add(c) : _content.remove(c))
            : null,
      );

  Widget _statusChip(TaskStatus s, String label) => FilterChip(
    label: Text(label),
    selected: _statuses.contains(s),
    onSelected: (v) => _reload(() => v ? _statuses.add(s) : _statuses.remove(s)),
  );

  // Field toggles only change how a card paints — no reload needed.
  Widget _fieldChip(_CardField f, String label) => FilterChip(
    label: Text(label),
    selected: _fields.contains(f),
    onSelected: (v) =>
        setState(() => v ? _fields.add(f) : _fields.remove(f)),
  );
}
