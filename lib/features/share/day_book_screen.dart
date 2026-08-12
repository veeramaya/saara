import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/platform.dart';
import '../../providers.dart';
import 'flipbook_html.dart';
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
  // One capture key per face (two faces per day, in card order).
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
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);

    final cards = <DayCardData>[];
    for (var d = 0; d < _days; d++) {
      final day = base.subtract(Duration(days: d));
      final tasks = await dao.tasksForDay(day);
      final log = await db.dayLogFor(DateFormat('yyyy-MM-dd').format(day));
      // A day earns a page if it has tasks or a day record — skip blank days.
      if (tasks.isEmpty && log == null) continue;
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
    if (!mounted) return;
    setState(() {
      _cards = cards;
      _keys = [for (var i = 0; i < cards.length * 2; i++) GlobalKey()];
      _page = 0;
      _loading = false;
    });
  }

  Future<void> _changeRange(int days) async {
    if (days == _days) return;
    setState(() => _days = days);
    await _load();
  }

  List<Widget> _faces() => [
    for (final c in _cards) ...[
      DayFace(data: c, open: true),
      DayFace(data: c, open: false),
    ],
  ];

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      // Let the off-screen faces settle a frame before capturing.
      await Future<void>.delayed(const Duration(milliseconds: 120));
      final pages = <Uint8List>[];
      final captions = <String>[];
      for (var c = 0; c < _cards.length; c++) {
        final label = DateFormat('EEE, d MMM').format(_cards[c].day);
        for (var f = 0; f < 2; f++) {
          final key = _keys[c * 2 + f];
          final boundary =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          if (data == null) continue;
          pages.add(data.buffer.asUint8List());
          captions.add('$label — ${f == 0 ? 'open' : 'close'}');
        }
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
    final faces = _faces();
    final captureFaces = _faces();
    if (_page >= faces.length) _page = 0;
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
                pages: faces,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${_cards.length} day${_cards.length == 1 ? '' : 's'} · '
                '${faces.length} pages — swipe to browse.',
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
        // Off-screen capture targets: every face, each under its own key.
        Positioned(
          left: 0,
          top: 0,
          child: Transform.translate(
            offset: const Offset(-5000, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < captureFaces.length; i++)
                  RepaintBoundary(key: _keys[i], child: captureFaces[i]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
