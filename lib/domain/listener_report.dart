import 'package:intl/intl.dart';

import 'report.dart';

/// A section of the committed-listener report the sharer can include or leave
/// out — the same "choose what travels" control the invitation/report card has.
/// The title line (whose week, and the date) is always present.
enum ListenerReportField { completion, counts, streak, byArea, footer }

const _allListenerFields = {
  ListenerReportField.completion,
  ListenerReportField.counts,
  ListenerReportField.streak,
  ListenerReportField.byArea,
  ListenerReportField.footer,
};

String listenerReportFieldLabel(ListenerReportField f) => switch (f) {
  ListenerReportField.completion => 'Completion %',
  ListenerReportField.counts => 'Counts',
  ListenerReportField.streak => 'Streak',
  ListenerReportField.byArea => 'By area',
  ListenerReportField.footer => 'Footer',
};

/// §13 committed-listener report — a template-based narrative generated
/// on-device from the integrity ledger (Tier 0). Delivery is via the user's own
/// apps (share sheet), never Realmaya infrastructure (§1.4).
///
/// [fields] chooses which sections travel; the sharer picks them before
/// sending. Defaults to everything so existing callers are unchanged.
String buildListenerReport({
  String? forName,
  required ReportSummary summary,
  required List<({String name, double score})> areas,
  required DateTime now,
  Set<ListenerReportField> fields = _allListenerFields,
}) {
  final b = StringBuffer();
  b.writeln(
    'Saara — ${forName == null ? 'my' : '$forName\'s'} week, '
    '${DateFormat.yMMMMd().format(now)}',
  );
  if (fields.contains(ListenerReportField.completion)) {
    b.writeln();
    b.writeln(
      'Kept my word ${(summary.weekCompletionRate * 100).round()}% of '
      'the time this week.',
    );
  }
  if (fields.contains(ListenerReportField.counts)) {
    b.writeln(
      '  Completed: ${summary.weekCompleted}'
      '   Missed: ${summary.weekMissed}'
      '   Rejected: ${summary.weekRejected}',
    );
  }
  if (fields.contains(ListenerReportField.streak)) {
    b.writeln(
      'Current streak: ${summary.streakDays} day'
      '${summary.streakDays == 1 ? '' : 's'}.',
    );
  }
  if (fields.contains(ListenerReportField.byArea) && areas.isNotEmpty) {
    b.writeln();
    b.writeln('By area:');
    for (final a in areas) {
      b.writeln('  • ${a.name}: ${(a.score * 100).round()}%');
    }
  }
  if (fields.contains(ListenerReportField.footer)) {
    b.writeln();
    b.writeln('— shared from Saara');
  }
  return b.toString();
}
