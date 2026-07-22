import 'package:intl/intl.dart';

import 'report.dart';

/// §13 committed-listener report — a template-based narrative generated
/// on-device from the integrity ledger (Tier 0). Delivery is via the user's own
/// apps (share sheet), never Realmaya infrastructure (§1.4).
String buildListenerReport({
  String? forName,
  required ReportSummary summary,
  required List<({String name, double score})> areas,
  required DateTime now,
}) {
  final b = StringBuffer();
  b.writeln(
    'Saara — ${forName == null ? 'my' : '$forName\'s'} week, '
    '${DateFormat.yMMMMd().format(now)}',
  );
  b.writeln();
  b.writeln(
    'Kept my word ${(summary.weekCompletionRate * 100).round()}% of '
    'the time this week.',
  );
  b.writeln(
    '  Completed: ${summary.weekCompleted}'
    '   Missed: ${summary.weekMissed}'
    '   Rejected: ${summary.weekRejected}',
  );
  b.writeln(
    'Current streak: ${summary.streakDays} day'
    '${summary.streakDays == 1 ? '' : 's'}.',
  );
  if (areas.isNotEmpty) {
    b.writeln();
    b.writeln('By area:');
    for (final a in areas) {
      b.writeln('  • ${a.name}: ${(a.score * 100).round()}%');
    }
  }
  b.writeln();
  b.writeln('— shared from Saara');
  return b.toString();
}
