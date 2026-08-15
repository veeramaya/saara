/// A self-contained, document-style HTML report (§13) — the "help-file" layout
/// the user asked for: a title, a table of contents, then sections of text and
/// plain data tables (line-matrix form). Everything is inlined — no server, no
/// fonts, no scripts beyond a tiny smooth-scroll — so it opens in any browser,
/// offline, and prints cleanly.
///
/// It is deliberately *text*, not card images: selectable, searchable, and
/// comprehensive. (The card "book" flipbook is the other output format.)
library;

/// One table inside a section — columns + rows of plain strings.
class ReportTable {
  const ReportTable({required this.columns, required this.rows, this.caption});
  final List<String> columns;
  final List<List<String>> rows;
  final String? caption;
}

/// A key/value block — for compact "field: value" summaries.
class ReportFacts {
  const ReportFacts(this.pairs);
  final List<(String, String)> pairs;
}

/// One section of the report: a heading, optional lead paragraphs, an optional
/// facts block, and an optional table. Empty sections are dropped by the caller.
class ReportSection {
  const ReportSection({
    required this.id,
    required this.title,
    this.lead,
    this.paragraphs = const [],
    this.facts,
    this.table,
  });
  final String id; // anchor id
  final String title;
  final String? lead;
  final List<String> paragraphs;
  final ReportFacts? facts;
  final ReportTable? table;

  bool get isEmpty =>
      (lead == null || lead!.isEmpty) &&
      paragraphs.isEmpty &&
      (facts == null || facts!.pairs.isEmpty) &&
      (table == null || table!.rows.isEmpty);
}

/// The whole document.
class ReportDoc {
  const ReportDoc({
    required this.title,
    required this.subtitle,
    required this.sections,
  });
  final String title;
  final String subtitle;
  final List<ReportSection> sections;
}

String buildReportHtml(ReportDoc doc) {
  final sections = doc.sections.where((s) => !s.isEmpty).toList();
  final toc = StringBuffer();
  for (var i = 0; i < sections.length; i++) {
    final s = sections[i];
    toc.writeln(
      '<li><a href="#${_attr(s.id)}">'
      '<span class="tocnum">${i + 1}</span>${_esc(s.title)}</a></li>',
    );
  }

  final body = StringBuffer();
  for (var i = 0; i < sections.length; i++) {
    final s = sections[i];
    body.writeln('<section id="${_attr(s.id)}">');
    body.writeln(
      '<h2><span class="secnum">${i + 1}</span>${_esc(s.title)}'
      '<a class="top" href="#top">&#8593; top</a></h2>',
    );
    if ((s.lead ?? '').isNotEmpty) {
      body.writeln('<p class="lead">${_esc(s.lead!)}</p>');
    }
    for (final p in s.paragraphs) {
      if (p.trim().isNotEmpty) body.writeln('<p>${_esc(p)}</p>');
    }
    if (s.facts != null && s.facts!.pairs.isNotEmpty) {
      body.writeln('<dl class="facts">');
      for (final (k, v) in s.facts!.pairs) {
        body.writeln('<dt>${_esc(k)}</dt><dd>${_esc(v)}</dd>');
      }
      body.writeln('</dl>');
    }
    if (s.table != null && s.table!.rows.isNotEmpty) {
      final t = s.table!;
      body.writeln('<div class="tablewrap"><table>');
      if (t.caption != null) {
        body.writeln('<caption>${_esc(t.caption!)}</caption>');
      }
      body.writeln('<thead><tr>');
      for (final c in t.columns) {
        body.writeln('<th>${_esc(c)}</th>');
      }
      body.writeln('</tr></thead><tbody>');
      for (final row in t.rows) {
        body.writeln('<tr>');
        for (var c = 0; c < t.columns.length; c++) {
          final cell = c < row.length ? row[c] : '';
          body.writeln('<td>${_esc(cell)}</td>');
        }
        body.writeln('</tr>');
      }
      body.writeln('</tbody></table></div>');
    }
    body.writeln('</section>');
  }

  return '''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>${_esc(doc.title)}</title>
<style>
  :root {
    --bg: #ffffff; --ink: #1b1613; --muted: #6d635c; --line: #e7e1da;
    --accent: #cc1a1a; --soft: #faf8f6; --zebra: #f6f2ee;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #141110; --ink: #f2ece7; --muted: #a99f97; --line: #2c2724;
      --accent: #ff6b6b; --soft: #1b1714; --zebra: #1a1613;
    }
  }
  * { box-sizing: border-box; }
  html { scroll-behavior: smooth; }
  body {
    margin: 0; background: var(--bg); color: var(--ink);
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    line-height: 1.55; -webkit-text-size-adjust: 100%;
  }
  .wrap { max-width: 820px; margin: 0 auto; padding: 32px 20px 80px; }
  header.doc { border-bottom: 3px solid var(--accent); padding-bottom: 16px; margin-bottom: 8px; }
  header.doc h1 { margin: 0 0 4px; font-size: 26px; letter-spacing: -0.4px; }
  header.doc .sub { color: var(--muted); font-size: 14px; }
  nav.toc {
    background: var(--soft); border: 1px solid var(--line); border-radius: 12px;
    padding: 14px 18px; margin: 22px 0 8px;
  }
  nav.toc h2 { margin: 0 0 8px; font-size: 12px; letter-spacing: 1.4px;
    text-transform: uppercase; color: var(--muted); }
  nav.toc ol { list-style: none; margin: 0; padding: 0; columns: 2; column-gap: 28px; }
  @media (max-width: 560px) { nav.toc ol { columns: 1; } }
  nav.toc li { margin: 4px 0; break-inside: avoid; }
  nav.toc a { color: var(--ink); text-decoration: none; }
  nav.toc a:hover { color: var(--accent); }
  .tocnum, .secnum {
    display: inline-block; min-width: 1.6em; color: var(--accent);
    font-variant-numeric: tabular-nums; font-weight: 700;
  }
  section { padding-top: 14px; margin-top: 18px; border-top: 1px solid var(--line); }
  h2 { font-size: 19px; margin: 8px 0 10px; display: flex; align-items: baseline; gap: 4px; }
  h2 .top { margin-left: auto; font-size: 11px; font-weight: 500; color: var(--muted);
    text-decoration: none; }
  h2 .top:hover { color: var(--accent); }
  p { margin: 8px 0; }
  p.lead { color: var(--muted); }
  dl.facts { display: grid; grid-template-columns: max-content 1fr; gap: 4px 16px;
    margin: 10px 0; }
  dl.facts dt { color: var(--muted); }
  dl.facts dd { margin: 0; font-weight: 600; }
  .tablewrap { overflow-x: auto; margin: 12px 0; }
  table { border-collapse: collapse; width: 100%; font-size: 13.5px; }
  caption { text-align: left; color: var(--muted); font-size: 12px; padding-bottom: 6px; }
  th, td { text-align: left; padding: 8px 10px; border-bottom: 1px solid var(--line);
    vertical-align: top; }
  th { font-size: 11px; letter-spacing: 0.6px; text-transform: uppercase;
    color: var(--muted); white-space: nowrap; }
  tbody tr:nth-child(even) { background: var(--zebra); }
  td { font-variant-numeric: tabular-nums; }
  footer.doc { margin-top: 40px; color: var(--muted); font-size: 12px; text-align: center; }
  @media print {
    nav.toc { break-after: page; }
    section { break-inside: avoid; }
    h2 .top { display: none; }
  }
</style>
</head>
<body>
<div class="wrap" id="top">
  <header class="doc">
    <h1>${_esc(doc.title)}</h1>
    <div class="sub">${_esc(doc.subtitle)}</div>
  </header>
  <nav class="toc">
    <h2>Contents</h2>
    <ol>
$toc
    </ol>
  </nav>
$body
  <footer class="doc">Generated on your device from your own record. Nothing was uploaded.</footer>
</div>
</body>
</html>''';
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _attr(String s) =>
    s.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-').toLowerCase();
