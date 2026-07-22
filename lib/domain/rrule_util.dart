/// §4 small RRULE string helpers. Deliberately string-level: the app only ever
/// needs to cap a rule, and round-tripping through a full parser would risk
/// rewriting parts of the rule the user never touched.
library;

/// Returns [rrule] with its `UNTIL` set to [until] (UTC, second precision),
/// replacing any existing `UNTIL` and dropping `COUNT` (the two are mutually
/// exclusive in RFC 5545).
///
/// Used to end a series just before a chosen date, so "this and following
/// events" can leave earlier dates alone while the new rule takes over.
String rruleWithUntil(String rrule, DateTime until) {
  final u = until.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  final stamp =
      '${u.year}${two(u.month)}${two(u.day)}T'
      '${two(u.hour)}${two(u.minute)}${two(u.second)}Z';

  final parts = rrule
      .replaceFirst(RegExp('^RRULE:', caseSensitive: false), '')
      .split(';')
      .where((p) => p.isNotEmpty)
      .where(
        (p) =>
            !p.toUpperCase().startsWith('UNTIL=') &&
            !p.toUpperCase().startsWith('COUNT='),
      )
      .toList();
  parts.add('UNTIL=$stamp');
  return parts.join(';');
}

/// True when the rule already ends (has an `UNTIL` or `COUNT`).
bool rruleIsBounded(String rrule) {
  final up = rrule.toUpperCase();
  return up.contains('UNTIL=') || up.contains('COUNT=');
}
