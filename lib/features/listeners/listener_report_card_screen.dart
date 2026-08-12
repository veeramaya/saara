import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform.dart';
import '../share/flipbook_html.dart';
import '../../data/database.dart';
import '../../domain/listener_report.dart';
import '../../domain/enums.dart';
import '../../domain/report.dart';
import '../../providers.dart';
import '../share/share_card_deck.dart';
import '../share/share_channels.dart';

/// §13 the committed-listener weekly report as a **shareable card deck** — the
/// same viewer the task/event report uses. A summary page, then a page each for
/// the counts and the per-area breakdown, flipped through in a built-in viewer
/// and shared as one image. The sharer picks which sections travel.
class ListenerReportCardScreen extends ConsumerStatefulWidget {
  const ListenerReportCardScreen({super.key, required this.listener});
  final CommittedListener listener;

  @override
  ConsumerState<ListenerReportCardScreen> createState() =>
      _ListenerReportCardScreenState();
}

class _ListenerReportCardScreenState
    extends ConsumerState<ListenerReportCardScreen> {
  final _cardKey = GlobalKey();
  final PageController _pager = PageController();
  int _page = 0;
  CardStyle _style = CardStyle.brand;
  bool _busy = false;
  // One capture key per page, for the HTML flipbook export.
  List<GlobalKey> _pageKeys = const [];

  // Everything on by default; the sharer turns sections off.
  final Set<ListenerReportField> _fields = {
    ListenerReportField.completion,
    ListenerReportField.counts,
    ListenerReportField.streak,
    ListenerReportField.byArea,
    ListenerReportField.footer,
  };

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  bool _on(ListenerReportField f) => _fields.contains(f);

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(reportSummaryProvider);
    final scoresAsync = ref.watch(areaScoresProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Share report')),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (summary) {
          final allScores = scoresAsync.valueOrNull ?? const [];
          final scoped = widget.listener.scope == ListenerScope.area
              ? allScores.where((s) => s.area.id == widget.listener.scopeId)
              : allScores;
          final areas = [
            for (final s in scoped)
              (name: s.area.displayName, score: s.score),
          ];
          return _content(summary, areas);
        },
      ),
    );
  }

  Widget _content(
    ReportSummary summary,
    List<({String name, double score})> areas,
  ) {
    // "By area" is only offered when there are scores.
    final offered = [
      ListenerReportField.completion,
      ListenerReportField.counts,
      ListenerReportField.streak,
      if (areas.isNotEmpty) ListenerReportField.byArea,
      ListenerReportField.footer,
    ];

    List<Widget> pagesFor(CardStyle style) =>
        _pages(style, summary, areas);
    final pages = pagesFor(_style);
    if (_page >= pages.length) _page = 0;
    final multi = pages.length > 1;

    // Fresh instances + keys for the per-page HTML flipbook export.
    final htmlPages = pagesFor(_style);
    if (_pageKeys.length != htmlPages.length) {
      _pageKeys = [for (var i = 0; i < htmlPages.length; i++) GlobalKey()];
    }

    final preview = multi
        ? PagedViewer(
            controller: _pager,
            pages: pages,
            page: _page,
            onPageChanged: (i) => setState(() => _page = i),
            dotColor: Theme.of(context).colorScheme.primary,
          )
        : RepaintBoundary(key: _cardKey, child: pages.first);

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
            Center(child: preview),
            if (multi) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Swipe through ${pages.length} pages — shared as one image '
                  'with all of them.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text('Include', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final f in offered)
                  FilterChip(
                    label: Text(listenerReportFieldLabel(f)),
                    selected: _on(f),
                    onSelected: (v) => setState(
                      () => v ? _fields.add(f) : _fields.remove(f),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: CardStyleSelector(
                style: _style,
                onChanged: (s) => setState(() => _style = s),
              ),
            ),
            const SizedBox(height: 16),
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
              onPressed: _busy ? null : () => _shareCard(summary, areas),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.public),
              label: Text(
                isDesktop
                    ? 'Save as web page (HTML)'
                    : 'Share as web page (HTML)',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _busy ? null : _shareHtml,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.notes),
              label: const Text('Share as text only'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _shareText(summary, areas),
            ),
            const SizedBox(height: 12),
            Text(
              'Only the sections you tick are shared. The report is generated on '
              'this device from your integrity ledger — nothing is uploaded.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        // Off-screen capture target: every page stacked into one image.
        if (multi)
          Positioned(
            left: 0,
            top: 0,
            child: Transform.translate(
              offset: const Offset(-5000, 0),
              child: RepaintBoundary(
                key: _cardKey,
                child: ReportComposite(pages: pagesFor(_style), style: _style),
              ),
            ),
          ),
        // Per-page off-screen targets for the HTML flipbook export.
        Positioned(
          left: 0,
          top: 0,
          child: Transform.translate(
            offset: const Offset(-5000, -12000),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < htmlPages.length; i++)
                  RepaintBoundary(key: _pageKeys[i], child: htmlPages[i]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _shareHtml() async {
    setState(() => _busy = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final imgs = <Uint8List>[];
      for (final k in _pageKeys) {
        final png = await capturePng(k, pixelRatio: 2.5);
        if (png != null) imgs.add(png);
      }
      if (imgs.isEmpty) throw 'Nothing to export yet.';
      final html = buildFlipbookHtml(
        title: 'My week — ${widget.listener.displayName}',
        pages: imgs,
      );
      if (!mounted) return;
      await shareOrSaveBytes(
        context,
        bytes: utf8.encode(html),
        fileName: 'saara-week.html',
        shareText: 'My week',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not export: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _text(
    ReportSummary summary,
    List<({String name, double score})> areas,
  ) => buildListenerReport(
    forName: widget.listener.displayName,
    summary: summary,
    areas: areas,
    now: DateTime.now(),
    fields: _fields,
  );

  Future<void> _shareCard(
    ReportSummary summary,
    List<({String name, double score})> areas,
  ) async {
    setState(() => _busy = true);
    try {
      await shareOrSaveCardImage(
        context,
        captureKey: _cardKey,
        text: _text(summary, areas),
        fileBase: 'saara-week',
      );
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

  Future<void> _shareText(
    ReportSummary summary,
    List<({String name, double score})> areas,
  ) async {
    final to = (widget.listener.email ?? '').trim();
    await shareTextViaChannels(
      context,
      text: _text(summary, areas),
      subject: 'Saara — my week',
      toEmail: to.contains('@') ? to : null,
      toPhone: to.contains('@') ? null : to,
    );
  }

  List<Widget> _pages(
    CardStyle style,
    ReportSummary summary,
    List<({String name, double score})> areas,
  ) {
    final p = CardPalette.of(style, null, null); // whole-week report → brand
    final name = widget.listener.displayName;
    final pct = (summary.weekCompletionRate * 100).round();

    final summaryBody = <Widget>[
      if (_on(ListenerReportField.completion)) ...[
        Text(
          '$pct%',
          style: TextStyle(
            color: p.ink,
            fontSize: 64,
            height: 1.0,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'kept my word this week',
          style: TextStyle(color: p.muted, fontSize: 15),
        ),
      ] else
        Text(
          'My week',
          style: TextStyle(
            color: p.ink,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
      if (_on(ListenerReportField.streak)) ...[
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.local_fire_department_outlined,
              size: 18,
              color: p.accent,
            ),
            const SizedBox(width: 6),
            Text(
              '${summary.streakDays} day'
              '${summary.streakDays == 1 ? '' : 's'} streak',
              style: TextStyle(
                color: p.ink,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    ];

    final pages = <Widget>[
      CardFrame(
        palette: p,
        eyebrowIcon: Icons.emoji_events_outlined,
        eyebrow: 'THIS WEEK',
        badgeName: 'FOR $name',
        body: summaryBody,
      ),
    ];

    if (_on(ListenerReportField.counts)) {
      pages.add(
        CardFrame(
          palette: p,
          eyebrowIcon: Icons.checklist_rtl_outlined,
          eyebrow: 'COUNTS',
          badgeName: 'FOR $name',
          body: [
            _countRow(Icons.check_circle_outline, 'Completed',
                summary.weekCompleted, p),
            _countRow(Icons.cancel_outlined, 'Missed', summary.weekMissed, p),
            _countRow(Icons.do_not_disturb_on_outlined, 'Rejected',
                summary.weekRejected, p),
          ],
        ),
      );
    }

    if (_on(ListenerReportField.byArea) && areas.isNotEmpty) {
      pages.add(
        CardFrame(
          palette: p,
          eyebrowIcon: Icons.donut_large_outlined,
          eyebrow: 'BY AREA',
          badgeName: 'FOR $name',
          body: [
            for (final a in areas.take(7)) _areaRow(a.name, a.score, p),
            if (areas.length > 7)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${areas.length - 7} more',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
              ),
          ],
        ),
      );
    }
    return pages;
  }

  Widget _countRow(IconData icon, String label, int value, CardPalette p) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: p.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: p.ink, fontSize: 16),
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                color: p.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );

  Widget _areaRow(String name, double score, CardPalette p) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: p.ink, fontSize: 14),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(score * 100).round()}%',
          style: TextStyle(
            color: p.ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
