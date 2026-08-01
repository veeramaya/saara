/// Central Government (DoPT) **gazetted** holidays — an informational reference
/// the user can tap from, never a claim about *their* day (§ Day Card).
///
/// Deliberately the Government of India *central* gazetted list only — not any
/// state list. Shown attributed ("per Govt of India"); the user's own calendar
/// stays the truth. A family may keep Diwali on the 9th though the gazette marks
/// the 8th — Saara only asks whether anything is planned around it.
///
/// Year-specific and bundled (offline). Movable festivals come straight from the
/// gazette, so dates are exact rather than guessed. Islamic dates the gazette
/// itself marks subject to moon sighting carry [tentative] = true, and Saara
/// shows that caveat. Each new year's list is added as the gazette publishes it.
class Holiday {
  const Holiday(this.month, this.day, this.name, {this.tentative = false});
  final int month;
  final int day;
  final String name;

  /// The gazette flags this date "subject to moon sighting" (the Islamic
  /// holidays). Shown with that honest caveat.
  final bool tentative;
}

/// 2026 Central Government gazetted holidays (DoPT), in date order.
const List<Holiday> _india2026 = [
  Holiday(1, 26, 'Republic Day'),
  Holiday(3, 4, 'Holi'),
  Holiday(3, 21, 'Id-ul-Fitr', tentative: true),
  Holiday(3, 26, 'Rama Navami'),
  Holiday(3, 31, 'Mahavir Jayanti'),
  Holiday(4, 3, 'Good Friday'),
  Holiday(5, 1, 'Buddha Purnima'),
  Holiday(5, 27, 'Id-ul-Zuha (Bakrid)', tentative: true),
  Holiday(6, 26, 'Muharram', tentative: true),
  Holiday(8, 15, 'Independence Day'),
  Holiday(8, 26, 'Id-e-Milad', tentative: true),
  Holiday(9, 4, 'Janmashtami'),
  Holiday(10, 2, 'Gandhi Jayanti'),
  Holiday(10, 20, 'Dussehra'),
  Holiday(11, 8, 'Diwali'),
  Holiday(11, 24, 'Guru Nanak Jayanti'),
  Holiday(12, 25, 'Christmas'),
];

/// region code -> year -> list. Only India ('IN') is seeded today.
const Map<String, Map<int, List<Holiday>>> _byRegion = {
  'IN': {2026: _india2026},
};

/// The full gazetted list for a region and year, or empty when we don't yet
/// bundle it (an unseeded region, or a year past the tables we ship).
List<Holiday> gazettedHolidays(String region, int year) =>
    _byRegion[region]?[year] ?? const [];

/// The gazetted holiday falling on [day], or null.
Holiday? holidayOn(DateTime day, {String region = 'IN'}) {
  for (final h in gazettedHolidays(region, day.year)) {
    if (h.month == day.month && h.day == day.day) return h;
  }
  return null;
}

/// Gazetted holidays from [from] (inclusive) within the next [withinDays],
/// each with how many days away it is — for the look-ahead nudges.
List<({Holiday holiday, DateTime date, int daysAway})> upcomingHolidays(
  DateTime from, {
  String region = 'IN',
  int withinDays = 14,
}) {
  final start = DateTime(from.year, from.month, from.day);
  final out = <({Holiday holiday, DateTime date, int daysAway})>[];
  // Look at this year and the next, so a late-December scan still sees January.
  for (final year in {start.year, start.year + 1}) {
    for (final h in gazettedHolidays(region, year)) {
      final date = DateTime(year, h.month, h.day);
      final away = date.difference(start).inDays;
      if (away >= 0 && away <= withinDays) {
        out.add((holiday: h, date: date, daysAway: away));
      }
    }
  }
  out.sort((a, b) => a.daysAway.compareTo(b.daysAway));
  return out;
}
