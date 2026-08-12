import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/platform.dart';
import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../providers.dart';
import 'flipbook_html.dart';
import 'report_card.dart';
import 'ritual_card_screen.dart';
import 'share_card_deck.dart';

/// §13 A **profile book** — the last N days as day cards, gathered into one
/// browser flipbook a committed listener outside Saara can open and flip
/// through. The book is a single self-contained HTML file (every card embedded
/// as an image); nothing is uploaded, and it works offline.
class DayBookScreen extends ConsumerStatefulWidget {
  const DayBookScreen({super.key});

  @override
  ConsumerState<DayBookScreen> createState() => _DayBookScreenState();
}

class _DayBookScreenState extends ConsumerState<DayBookScreen> {
  final PageController _pager = PageController();
  int _page = 0;
  int _days = 7;
  bool _loading = true;
  bool _busy = false;

  List<DayCardData> _cards = const [];
  // Completed tasks/events in range → one report card each, after the days.
  List<({Task task, Area? area})> _reports = const [];
  // One capture key per page (two faces per day, then one per report).
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

  Future<void> _load() async {
    setState(() => _loading = true);
    final dao = ref.read(taskDaoProvider);
    final db = ref.read(appDatabaseProvider);
    final areas = await ref.read(activeAreasProvider.future);
    final areaById = {for (final a in areas) a.id: a};
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);

    final cards = <DayCardData>[];
    final reports = <({Task task, Area? area})>[];
    final reportSeen = <String>{};
    for (var d = 0; d < _days; d++) {
      final day = base.subtract(Duration(days: d));
      final tasks = await dao.tasksForDay(day);
      final log = await db.dayLogFor(DateFormat('yyyy-MM-dd').format(day));
      // A day earns a page if it has tasks or a day record — skip blank days.
      if (tasks.isNotEmpty || log != null) {
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
      // Every completed task/event in range earns its own report card.
      for (final t in tasks) {
        if (t.status == TaskStatus.completed && reportSeen.add(t.id)) {
          reports.add((
            task: t,
            area: t.areaId == null ? null : areaById[t.areaId],
          ));
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _cards = cards;
      _reports = reports;
      final total = cards.length * 2 + reports.length;
      _keys = [for (var i = 0; i < total; i++) GlobalKey()];
      _page = 0;
      _loading = false;
    });
  }

  Future<void> _changeRange(int days) async {
    if (days == _days) return;
    setState(() => _days = days);
    await _load();
  }

  /// The book's pages, in order: each day's two faces, then a report card per
  /// completed item. Fresh widget instances each call (a widget can't sit in
  /// two places in the tree — preview and off-screen capture need their own).
  List<({Widget page, String caption})> _pages() {
    final out = <({Widget page, String caption})>[];
    for (final c in _cards) {
      final label = DateFormat('EEE, d MMM').format(c.day);
      out.add((page: DayFace(data: c, open: true), caption: '$label — open'));
      out.add((page: DayFace(data: c, open: false), caption: '$label — close'));
    }
    for (final r in _reports) {
      final p = CardPalette.of(CardStyle.brand, r.area?.color, r.area?.icon);
      out.add((
        page: _box(
          reportSummaryCard(
            task: r.task,
            palette: p,
            areaName: r.area?.displayName,
          ),
        ),
        caption: 'Report — ${r.task.title}',
      ));
    }
    return out;
  }

  /// Pad a 360×360 report card to the day-face footprint so the book's pages
  /// are all one size.
  Widget _box(Widget card) =>
      SizedBox(width: 380, height: 466, child: Center(child: card));

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      // Let the off-screen pages settle a frame before capturing.
      await Future<void>.delayed(const Duration(milliseconds: 120));
      final meta = _pages();
      final pages = <Uint8List>[];
      final captions = <String>[];
      for (var i = 0; i < meta.length && i < _keys.length; i++) {
        final boundary =
            _keys[i].currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) continue;
        pages.add(data.buffer.asUint8List());
        captions.add(meta[i].caption);
      }
      if (pages.isEmpty) throw 'Nothing to export yet.';
      final html = buildFlipbookHtml(
        title: 'My day book',
        pages: pages,
        captions: captions,
      );
      if (!mounted) return;
      await shareOrSaveBytes(
        context,
        bytes: utf8.encode(html),
        fileName: 'saara-day-book.html',
        shareText: 'My day book',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Day book'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.date_range),
            tooltip: 'Range',
            initialValue: _days,
            onSelected: _changeRange,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 7, child: Text('Last 7 days')),
              PopupMenuItem(value: 14, child: Text('Last 14 days')),
              PopupMenuItem(value: 30, child: Text('Last 30 days')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No days to bind yet. Open or close a day, or add a few '
                  'tasks, and they’ll appear here as pages.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _content(),
    );
  }

  Widget _content() {
    // Separate instances for the preview vs the off-screen capture — the same
    // widget object can't sit in two places in the tree.
    final pages = _pages();
    final capturePages = _pages();
    if (_page >= pages.length) _page = 0;
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
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
                '${_reports.length} report${_reports.length == 1 ? '' : 's'} · '
                '${pages.length} pages — swipe to browse.',
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
              label: Text(
                isDesktop ? 'Save book (HTML)' : 'Share book (HTML)',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _busy ? null : _export,
            ),
            const SizedBox(height: 12),
            Text(
              'The book is one self-contained web page — every card embedded as '
              'an image. It opens in any browser, works offline, and nothing is '
              'uploaded. Send it to a committed listener over WhatsApp or mail; '
              'they flip through it with no app to install.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        // Off-screen capture targets: every page, each under its own key.
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
}
