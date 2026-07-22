/// Maps a human "repeat" phrase (e.g. from an Excel `Repeat` column) to an
/// iCalendar RRULE body. Deterministic (Tier 0). Unmappable phrases return null
/// and the caller imports the task as non-recurring, flagging it (§12 spirit).
class RecurrencePhraseMapper {
  const RecurrencePhraseMapper();

  static const _weekdayCodes = {
    'monday': 'MO',
    'mon': 'MO',
    'tuesday': 'TU',
    'tue': 'TU',
    'tues': 'TU',
    'wednesday': 'WE',
    'wed': 'WE',
    'thursday': 'TH',
    'thu': 'TH',
    'thurs': 'TH',
    'friday': 'FR',
    'fri': 'FR',
    'saturday': 'SA',
    'sat': 'SA',
    'sunday': 'SU',
    'sun': 'SU',
  };

  /// Returns an RRULE body (no `RRULE:` prefix) or null if unmappable.
  String? toRrule(String? phrase) {
    if (phrase == null) return null;
    final s = phrase.toLowerCase().trim();
    if (s.isEmpty) return null;

    if (s == 'every day' || s == 'daily') return 'FREQ=DAILY';
    if (s == 'every week' || s == 'weekly') return 'FREQ=WEEKLY';
    if (s == 'every month' || s == 'monthly') return 'FREQ=MONTHLY';
    if (s == 'weekdays') return 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR';
    if (s == 'weekends') return 'FREQ=WEEKLY;BYDAY=SA,SU';

    final everyNWeeks = RegExp(r'^every\s+(\d+)\s+weeks?$').firstMatch(s);
    if (everyNWeeks != null) {
      return 'FREQ=WEEKLY;INTERVAL=${everyNWeeks.group(1)}';
    }

    final everyNDays = RegExp(r'^every\s+(\d+)\s+days?$').firstMatch(s);
    if (everyNDays != null) {
      return 'FREQ=DAILY;INTERVAL=${everyNDays.group(1)}';
    }

    // "every mon, wed" / "every mon wed fri" — every token must be a weekday.
    final everyDays = RegExp(r'^every\s+(.+)$').firstMatch(s);
    if (everyDays != null) {
      final tokens = everyDays
          .group(1)!
          .split(RegExp(r'[,\s]+'))
          .where((t) => t.trim().isNotEmpty)
          .toList();
      final codes = <String>[];
      for (final t in tokens) {
        final code = _weekdayCodes[t.trim()];
        if (code != null) codes.add(code);
      }
      if (codes.isNotEmpty && codes.length == tokens.length) {
        return 'FREQ=WEEKLY;BYDAY=${codes.join(',')}';
      }
    }

    return null; // unmappable → non-recurring + flag
  }
}
