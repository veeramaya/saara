import 'package:collection/collection.dart';

import 'parsed_task.dart';

/// §6 date/time/duration/recurrence grammar. Deterministic (Tier 0) — no AI.
/// This is a focused hand-rolled grammar covering the PRD's examples; extend it
/// as new phrasings appear (add a case + a test, keep it deterministic).
class DateGrammar {
  DateGrammar({DateTime Function()? clock}) : _now = clock ?? DateTime.now;
  final DateTime Function() _now;

  static const _weekdays = {
    'monday': DateTime.monday,
    'mon': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'tue': DateTime.tuesday,
    'tues': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'wed': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'thu': DateTime.thursday,
    'thurs': DateTime.thursday,
    'friday': DateTime.friday,
    'fri': DateTime.friday,
    'saturday': DateTime.saturday,
    'sat': DateTime.saturday,
    'sunday': DateTime.sunday,
    'sun': DateTime.sunday,
  };

  // ---- Duration (§6) -------------------------------------------------------
  // "for 45 min | 45m | 1.5 hr | half an hour"
  Extracted<int> duration(String input) {
    final lower = input.toLowerCase();

    if (RegExp(r'half an hour|half hour').hasMatch(lower)) {
      final span = RegExp(
        r'(for\s+)?half an hour|half hour',
      ).firstMatch(lower)?.group(0);
      return Extracted(30, 0.9, rawSpan: span);
    }

    final hr = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:hours?|hrs?|h)\b',
    ).firstMatch(lower);
    if (hr != null) {
      final value = double.parse(hr.group(1)!);
      return Extracted((value * 60).round(), 0.9, rawSpan: hr.group(0));
    }

    final min = RegExp(r'(\d+)\s*(?:minutes?|mins?|m)\b').firstMatch(lower);
    if (min != null) {
      return Extracted(int.parse(min.group(1)!), 0.9, rawSpan: min.group(0));
    }
    return Extracted.none();
  }

  // ---- Recurrence → RRULE (§6) --------------------------------------------
  // every|daily|weekdays|weekends|every other <weekday>|1st|2nd <weekday> of month
  Extracted<String> recurrence(String input) {
    final lower = input.toLowerCase();

    if (RegExp(r'\b(daily|every day)\b').hasMatch(lower)) {
      return const Extracted('FREQ=DAILY', 0.9, rawSpan: 'daily');
    }
    if (RegExp(r'\bweekdays\b').hasMatch(lower)) {
      return const Extracted(
        'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
        0.9,
        rawSpan: 'weekdays',
      );
    }
    if (RegExp(r'\bweekends\b').hasMatch(lower)) {
      return const Extracted(
        'FREQ=WEEKLY;BYDAY=SA,SU',
        0.9,
        rawSpan: 'weekends',
      );
    }

    // "1st/2nd/3rd/4th <weekday> of month"
    final ordinal = RegExp(
      r'\b(1st|2nd|3rd|4th)\s+(\w+)\s+of\s+(?:the\s+)?month\b',
    ).firstMatch(lower);
    if (ordinal != null) {
      final n = {'1st': 1, '2nd': 2, '3rd': 3, '4th': 4}[ordinal.group(1)!]!;
      final wd = _weekdays[ordinal.group(2)!];
      if (wd != null) {
        return Extracted(
          'FREQ=MONTHLY;BYDAY=$n${_byDay(wd)}',
          0.85,
          rawSpan: ordinal.group(0),
        );
      }
    }

    // "every other <weekday>" → INTERVAL=2
    final everyOther = RegExp(r'\bevery other\s+(\w+)\b').firstMatch(lower);
    if (everyOther != null) {
      final wd = _weekdays[everyOther.group(1)!];
      if (wd != null) {
        return Extracted(
          'FREQ=WEEKLY;INTERVAL=2;BYDAY=${_byDay(wd)}',
          0.85,
          rawSpan: everyOther.group(0),
        );
      }
    }

    // "every <weekday>[, <weekday>]"
    final every = RegExp(r'\bevery\s+([a-z,\s]+)\b').firstMatch(lower);
    if (every != null) {
      final days = <String>[];
      for (final token in every.group(1)!.split(RegExp(r'[,\s]+'))) {
        final wd = _weekdays[token.trim()];
        if (wd != null) days.add(_byDay(wd));
      }
      if (days.isNotEmpty) {
        return Extracted(
          'FREQ=WEEKLY;BYDAY=${days.join(',')}',
          0.85,
          rawSpan: every.group(0),
        );
      }
    }

    return Extracted.none();
  }

  // ---- Relative date/time (§6) --------------------------------------------
  // tomorrow | next tue | in 3 days | tonight (20:00) | today | "at 3pm"
  Extracted<DateTime> dateTimeOf(String input) {
    final lower = input.toLowerCase();
    final now = _now();
    DateTime? date;
    String? span;
    var confidence = 0.0;

    if (RegExp(r'\btonight\b').hasMatch(lower)) {
      date = DateTime(now.year, now.month, now.day, 20); // §6 tonight = 20:00
      span = 'tonight';
      confidence = 0.85;
    } else if (RegExp(r'\btomorrow\b').hasMatch(lower)) {
      final d = now.add(const Duration(days: 1));
      date = DateTime(d.year, d.month, d.day);
      span = 'tomorrow';
      confidence = 0.85;
    } else if (RegExp(r'\btoday\b').hasMatch(lower)) {
      date = DateTime(now.year, now.month, now.day);
      span = 'today';
      confidence = 0.8;
    } else {
      final inDays = RegExp(r'\bin\s+(\d+)\s+days?\b').firstMatch(lower);
      if (inDays != null) {
        final d = now.add(Duration(days: int.parse(inDays.group(1)!)));
        date = DateTime(d.year, d.month, d.day);
        span = inDays.group(0);
        confidence = 0.8;
      } else {
        final next = RegExp(r'\bnext\s+(\w+)\b').firstMatch(lower);
        if (next != null && _weekdays.containsKey(next.group(1))) {
          date = _nextWeekday(now, _weekdays[next.group(1)]!);
          span = next.group(0);
          confidence = 0.8;
        }
      }
    }

    if (date == null) return Extracted.none();

    // Layer an explicit clock time on top of the resolved date if present.
    final time = _timeOfDay(lower);
    if (time != null) {
      date = DateTime(date.year, date.month, date.day, time.$1, time.$2);
      confidence = (confidence + 0.1).clamp(0, 1);
    }

    return Extracted(date, confidence, rawSpan: span);
  }

  /// "at 3pm | 3:30pm | 15:00" → (hour24, minute).
  (int, int)? _timeOfDay(String lower) {
    final m = RegExp(r'\b(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b')
        .allMatches(lower)
        // Skip bare numbers that are part of "in 3 days" etc. by requiring am/pm
        // or a colon.
        .where((x) => x.group(3) != null || x.group(2) != null)
        .firstOrNull;
    if (m == null) return null;
    var hour = int.parse(m.group(1)!);
    final minute = m.group(2) == null ? 0 : int.parse(m.group(2)!);
    final meridiem = m.group(3);
    if (meridiem == 'pm' && hour < 12) hour += 12;
    if (meridiem == 'am' && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) return null;
    return (hour, minute);
  }

  DateTime _nextWeekday(DateTime from, int weekday) {
    var d = DateTime(
      from.year,
      from.month,
      from.day,
    ).add(const Duration(days: 1));
    while (d.weekday != weekday) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  static String _byDay(int weekday) => const {
    DateTime.monday: 'MO',
    DateTime.tuesday: 'TU',
    DateTime.wednesday: 'WE',
    DateTime.thursday: 'TH',
    DateTime.friday: 'FR',
    DateTime.saturday: 'SA',
    DateTime.sunday: 'SU',
  }[weekday]!;
}
