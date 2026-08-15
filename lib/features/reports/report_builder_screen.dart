import 'dart:convert';

import 'package:drift/drift.dart' show OrderingMode, OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/platform.dart';
import '../../domain/enums.dart';
import '../../domain/ledger_report.dart';
import '../../domain/reliability.dart';
import '../../providers.dart';
import '../common/task_status_icon.dart';
import '../share/day_book_screen.dart';
import '../share/share_card_deck.dart';
import 'report_html.dart';

/// §13 A comprehensive **report builder** — a small dashboard where you pick a
/// range, the sections, and which fields each table shows, then generate a
/// self-contained HTML document (contents + text + tables). Everything is
/// computed on-device from your own record; nothing is uploaded. The card
/// "book" is the other format, one tap away.
class ReportBuilderScreen extends ConsumerStatefulWidget {
  const ReportBuilderScreen({super.key});

  @override
  ConsumerState<ReportBuilderScreen> createState() =>
      _ReportBuilderScreenState();
}

enum _Sec { overview, progress, tasks, events, daily, listeners }

enum _Col { when, status, area, duration, location, priority, notes }

String _secLabel(_Sec s) => switch (s) {
  _Sec.overview => 'Overview',
  _Sec.progress => 'Progress by area',
  _Sec.tasks => 'Tasks',
  _Sec.events => 'Events',
  _Sec.daily => 'Daily records',
  _Sec.listeners => 'Committed listeners',
};

String _colLabel(_Col c) => switch (c) {
  _Col.when => 'When',
  _Col.status => 'Status',
  _Col.area => 'Area',
  _Col.duration => 'Duration',
  _Col.location => 'Location',
  _Col.priority => 'Given-word ★',
  _Col.notes => 'Notes',
};

class _ReportBuilderScreenState extends ConsumerState<ReportBuilderScreen> {
  int _days = 30;
  bool _busy = false;

  final Set<_Sec> _sections = {..._Sec.values};
  final Set<_Col> _taskCols = {_Col.when, _Col.status, _Col.area};
  final Set<_Col> _eventCols = {
    _Col.when,
    _Col.status,
    _Col.area,
    _Col.location,
  };

  bool _on(_Sec s) => _sections.contains(s);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Build report')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          _label('Period'),
          Wrap(
            spacing: 8,
            children: [
              for (final n in const [7, 30, 90, 365])
                ChoiceChip(
                  label: Text(n == 365 ? '1 year' : '$n days'),
                  selected: _days == n,
                  onSelected: (_) => setState(() => _days = n),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _label('Sections to include'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final s in _Sec.values)
                FilterChip(
                  label: Text(_secLabel(s)),
                  selected: _on(s),
                  onSelected: (v) => setState(
                    () => v ? _sections.add(s) : _sections.remove(s),
                  ),
                ),
            ],
          ),
          if (_on(_Sec.tasks)) ...[
            const SizedBox(height: 16),
            _label('Task columns'),
            _colChips(
              const [
                _Col.when,
                _Col.status,
                _Col.area,
                _Col.duration,
                _Col.priority,
                _Col.notes,
              ],
              _taskCols,
            ),
          ],
          if (_on(_Sec.events)) ...[
            const SizedBox(height: 16),
            _label('Event columns'),
            _colChips(
              const [
                _Col.when,
                _Col.status,
                _Col.area,
                _Col.duration,
                _Col.location,
                _Col.notes,
              ],
              _eventCols,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(isDesktop ? Icons.download : Icons.description_outlined),
            label: Text(
              isDesktop ? 'Save report (HTML)' : 'Share report (HTML)',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _busy ? null : _generate,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.auto_stories_outlined),
            label: const Text('Prefer a card book instead'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DayBookScreen()),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The report is one self-contained web page — a table of contents, '
            'then your chosen sections as text and tables. It opens in any '
            'browser, works offline, and is built entirely on this device from '
            'your own record. Nothing is uploaded.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: Theme.of(context).textTheme.labelLarge),
  );

  Widget _colChips(List<_Col> cols, Set<_Col> selected) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      for (final c in cols)
        FilterChip(
          label: Text(_colLabel(c)),
          selected: selected.contains(c),
          onSelected: (v) => setState(
            () => v ? selected.add(c) : selected.remove(c),
          ),
        ),
    ],
  );

  // --- generation ----------------------------------------------------------

  Future<void> _generate() async {
    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      final to = DateTime(now.year, now.month, now.day).add(
        const Duration(days: 1),
      );
      final from = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: _days - 1));

      final db = ref.read(appDatabaseProvider);
      final dao = ref.read(taskDaoProvider);
      final areas = await ref.read(activeAreasProvider.future);
      final areaName = {for (final a in areas) a.id: a.displayName};

      final sections = <ReportSection>[];
      if (_on(_Sec.overview)) {
        sections.add(await _overview(dao, from, to));
      }
      if (_on(_Sec.progress)) {
        sections.add(await _progress(dao, areas, from, to));
      }
      if (_on(_Sec.tasks) || _on(_Sec.events)) {
        final all = await dao.tasksBetween(from, to);
        if (_on(_Sec.tasks)) {
          sections.add(
            _itemTable(
              id: 'tasks',
              title: 'Tasks',
              items: all.where((t) => t.kind != TaskKind.event).toList(),
              cols: _taskCols,
              areaName: areaName,
            ),
          );
        }
        if (_on(_Sec.events)) {
          sections.add(
            _itemTable(
              id: 'events',
              title: 'Events',
              items: all.where((t) => t.kind == TaskKind.event).toList(),
              cols: _eventCols,
              areaName: areaName,
            ),
          );
        }
      }
      if (_on(_Sec.daily)) {
        sections.add(await _daily(db, from, to));
      }
      if (_on(_Sec.listeners)) {
        sections.add(await _listeners(db));
      }

      final period =
          '${DateFormat('d MMM yyyy').format(from)} – '
          '${DateFormat('d MMM yyyy').format(now)}';
      final doc = ReportDoc(
        title: 'Saara — my integrity report',
        subtitle:
            '$period · generated ${DateFormat('d MMM yyyy, h:mm a').format(now)}',
        sections: sections,
      );
      final html = buildReportHtml(doc);
      if (!mounted) return;
      await shareOrSaveBytes(
        context,
        bytes: utf8.encode(html),
        fileName: 'saara-report.html',
        shareText: 'My Saara report',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not build the report: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<ReportSection> _overview(
    dynamic dao,
    DateTime from,
    DateTime to,
  ) async {
    final entries = await dao.ledgerEntriesBetween(from, to);
    final released = await dao.releasedTaskIds();
    final byArea = foldByArea(entries, legacyReleased: released);
    var kept = 0, broken = 0, answered = 0;
    byArea.forEach((_, s) {
      kept += s.kept;
      broken += s.broken;
      answered += s.answered;
    });
    final ratio = overallRatio(byArea); // 0..1
    final pct = (ratio * 100).round();
    final summary = await ref.read(reportSummaryProvider.future);
    return ReportSection(
      id: 'overview',
      title: 'Overview',
      lead: 'How reliably you kept your word over this period. The number is a '
          'compass, not a verdict.',
      facts: ReportFacts([
        ('Effectiveness', '$pct%'),
        ('Reliability level', reliabilityLevelName(pct.toDouble())),
        ('Kept', '$kept'),
        ('Missed or fell short', '$broken'),
        ('Answered commitments', '$answered'),
        ('Current streak', '${summary.streakDays} '
            'day${summary.streakDays == 1 ? '' : 's'}'),
      ]),
    );
  }

  Future<ReportSection> _progress(
    dynamic dao,
    List<dynamic> areas,
    DateTime from,
    DateTime to,
  ) async {
    final entries = await dao.ledgerEntriesBetween(from, to);
    final released = await dao.releasedTaskIds();
    final byArea = foldByArea(entries, legacyReleased: released);
    final rows = <List<String>>[];
    for (final a in areas) {
      final s = byArea[a.id];
      if (s == null || !s.hasData) continue;
      final pct = (s.ratio * 100).round();
      rows.add([
        a.displayName as String,
        '${s.answered}',
        '${s.kept}',
        '${s.broken}',
        '$pct%',
        reliabilityLevelName(pct.toDouble()),
      ]);
    }
    return ReportSection(
      id: 'progress',
      title: 'Progress by area',
      lead: 'Where you are reliable, and where the work is — each area scored '
          'on its own.',
      table: ReportTable(
        columns: const [
          'Area',
          'Committed',
          'Kept',
          'Missed',
          'Effectiveness',
          'Level',
        ],
        rows: rows,
      ),
    );
  }

  ReportSection _itemTable({
    required String id,
    required String title,
    required List<dynamic> items,
    required Set<_Col> cols,
    required Map<String, String> areaName,
  }) {
    final columns = <String>['Title', for (final c in _orderCols(cols)) _colLabel(c)];
    final rows = <List<String>>[];
    for (final t in items) {
      final when = (t.scheduledStart ?? t.dueDate) as DateTime?;
      final row = <String>[t.title as String];
      for (final c in _orderCols(cols)) {
        row.add(_cell(c, t, when, areaName));
      }
      rows.add(row);
    }
    return ReportSection(
      id: id,
      title: title,
      lead: '${items.length} '
          '${title.toLowerCase()} in this period.',
      table: ReportTable(columns: columns, rows: rows),
    );
  }

  // Keep a stable column order regardless of tap order.
  List<_Col> _orderCols(Set<_Col> cols) =>
      [for (final c in _Col.values) if (cols.contains(c)) c];

  String _cell(
    _Col c,
    dynamic t,
    DateTime? when,
    Map<String, String> areaName,
  ) {
    switch (c) {
      case _Col.when:
        return when == null ? '—' : DateFormat('EEE d MMM, h:mm a').format(when);
      case _Col.status:
        return taskStatusLabel(t.status, when);
      case _Col.area:
        return t.areaId == null ? '—' : (areaName[t.areaId] ?? '—');
      case _Col.duration:
        final d = t.durationMin as int?;
        return d == null ? '—' : _fmtMin(d);
      case _Col.location:
        return ((t.locationName as String?) ?? '').trim().isEmpty
            ? '—'
            : (t.locationName as String);
      case _Col.priority:
        return (t.priority as int) > 0 ? '★' : '';
      case _Col.notes:
        return ((t.notes as String?) ?? '').trim().replaceAll('\n', ' ');
    }
  }

  static String _fmtMin(int m) {
    if (m < 60) return '${m}m';
    final h = m ~/ 60, r = m % 60;
    return r == 0 ? '${h}h' : '${h}h ${r}m';
  }

  Future<ReportSection> _daily(dynamic db, DateTime from, DateTime to) async {
    final fromKey = DateFormat('yyyy-MM-dd').format(from);
    final toKey = DateFormat('yyyy-MM-dd').format(to);
    final logs =
        await (db.select(db.dayLogs)
              ..where(
                (d) =>
                    d.date.isBiggerOrEqualValue(fromKey) &
                    d.date.isSmallerOrEqualValue(toKey),
              )
              ..orderBy([(d) => OrderingTerm(expression: d.date, mode: OrderingMode.desc)]))
            .get();
    final rows = <List<String>>[];
    for (final l in logs) {
      final decl = (l.declaration as String?)?.trim() ?? '';
      final refl = (l.reflection as String?)?.trim() ?? '';
      if (decl.isEmpty && refl.isEmpty && l.closedAt == null) continue;
      rows.add([
        _prettyDate(l.date as String),
        decl.isEmpty ? '—' : decl,
        refl.isEmpty ? '—' : refl,
        l.closedAt != null ? 'Closed' : (l.openedAt != null ? 'Open' : '—'),
      ]);
    }
    return ReportSection(
      id: 'daily',
      title: 'Daily records',
      lead: 'Your own words — the day you opened with, and how you restored it '
          'at the close.',
      table: ReportTable(
        columns: const ['Date', 'Declaration', 'Restoration', 'State'],
        rows: rows,
      ),
    );
  }

  static String _prettyDate(String key) {
    final d = DateTime.tryParse(key);
    return d == null ? key : DateFormat('EEE, d MMM yyyy').format(d);
  }

  Future<ReportSection> _listeners(dynamic db) async {
    final listeners = await db.select(db.committedListeners).get();
    final rows = <List<String>>[];
    for (final l in listeners) {
      final fb =
          await (db.select(db.listenerFeedbacks)
                ..where((f) => f.listenerId.equals(l.id))
                ..orderBy([
                  (f) => OrderingTerm(
                    expression: f.createdAt,
                    mode: OrderingMode.desc,
                  ),
                ])
                ..limit(1))
              .getSingleOrNull();
      final rating = fb == null ? '—' : '${fb.ratingPct}%';
      final level = fb == null
          ? '—'
          : reliabilityLevelName((fb.ratingPct as int).toDouble());
      final comment = fb == null
          ? ''
          : ((fb.comment as String?) ?? '').trim().replaceAll('\n', ' ');
      final when = fb == null
          ? ''
          : DateFormat('d MMM yyyy').format(fb.createdAt as DateTime);
      rows.add([l.displayName as String, rating, level, comment, when]);
    }
    return ReportSection(
      id: 'listeners',
      title: 'Committed listeners',
      lead: 'A word isn\'t fully kept until it lands with the person you gave '
          'it to. Here is how your listeners see it.',
      table: ReportTable(
        columns: const ['Listener', 'Their rating', 'Level', 'Comment', 'When'],
        rows: rows,
      ),
    );
  }
}
