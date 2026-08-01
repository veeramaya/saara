/// "What's special in the world today" — the card's context layer (§ Day Card).
///
/// Bundled and **date-deterministic** (like the daily quotes were), so it costs
/// nothing to sync and works fully offline. This is Saara's own curated set of
/// fixed-date world observances — a gentle sense of how humanity marks the day,
/// not an information feed. Saara empowers you to declare and honour your word;
/// this is only context beside it.
///
/// Movable festivals (Diwali, Eid, Lunar New Year, Easter) shift each year and
/// live in a separate per-year table used by the look-ahead nudges — not here.
/// Days with no entry simply show no world line; the card is complete without
/// it. Optional online enrichment (Wikipedia "On this day") can be layered on
/// later, sending only the date.
class WorldDay {
  const WorldDay(this.title, this.note);
  final String title;

  /// One warm line of context. Kept factual and unifying, never preachy.
  final String note;
}

/// Keyed by 'MM-DD'. A curated starter set of widely-observed, fixed-date world
/// days; grown over time.
const Map<String, WorldDay> _worldDays = {
  '01-01': WorldDay('New Year\'s Day', 'A fresh page for much of the world.'),
  '01-24': WorldDay(
    'International Day of Education',
    'The world honours learning as a path out of every hardship.',
  ),
  '02-04': WorldDay(
    'World Cancer Day',
    'A day of solidarity with everyone touched by it.',
  ),
  '02-11': WorldDay(
    'Women and Girls in Science Day',
    'Celebrating the minds shaping tomorrow.',
  ),
  '02-13': WorldDay('World Radio Day', 'A century of voices carried on the air.'),
  '02-20': WorldDay(
    'World Day of Social Justice',
    'A shared wish for fairness everywhere.',
  ),
  '02-21': WorldDay(
    'International Mother Language Day',
    'Honouring every tongue people think and dream in.',
  ),
  '03-03': WorldDay('World Wildlife Day', 'A day for the creatures we share Earth with.'),
  '03-08': WorldDay(
    'International Women\'s Day',
    'The world honours the women in every life.',
  ),
  '03-20': WorldDay(
    'International Day of Happiness',
    'A reminder that well-being matters as much as progress.',
  ),
  '03-21': WorldDay('World Poetry Day', 'A day for the words that move us.'),
  '03-22': WorldDay('World Water Day', 'Gratitude for what gives all life.'),
  '04-02': WorldDay(
    'World Autism Awareness Day',
    'A day for understanding and belonging.',
  ),
  '04-07': WorldDay('World Health Day', 'The world turns toward well-being.'),
  '04-22': WorldDay('Earth Day', 'A billion people tending one home.'),
  '04-23': WorldDay('World Book Day', 'A day for the stories that shape us.'),
  '05-01': WorldDay(
    'International Workers\' Day',
    'Honouring the dignity of work everywhere.',
  ),
  '05-03': WorldDay('World Press Freedom Day', 'A day for truth freely told.'),
  '05-15': WorldDay(
    'International Day of Families',
    'The world honours the people we come home to.',
  ),
  '05-22': WorldDay(
    'Day for Biological Diversity',
    'Celebrating the web of life.',
  ),
  '06-05': WorldDay('World Environment Day', 'The largest day of action for nature.'),
  '06-08': WorldDay('World Oceans Day', 'Gratitude for the blue that holds us.'),
  '06-20': WorldDay(
    'World Refugee Day',
    'Solidarity with those far from home.',
  ),
  '06-21': WorldDay(
    'International Day of Yoga',
    'Millions breathe and steady themselves together.',
  ),
  '07-11': WorldDay('World Population Day', 'Eight billion stories, and counting.'),
  '07-30': WorldDay(
    'International Day of Friendship',
    'The world honours the bonds we choose.',
  ),
  '08-12': WorldDay(
    'International Youth Day',
    'A day for those carrying the future.',
  ),
  '08-19': WorldDay(
    'World Humanitarian Day',
    'Honouring the people who show up for others.',
  ),
  '09-05': WorldDay(
    'International Day of Charity',
    'A day for quiet, ordinary generosity.',
  ),
  '09-08': WorldDay('International Literacy Day', 'The gift of reading, celebrated.'),
  '09-21': WorldDay(
    'International Day of Peace',
    'A shared pause, and a shared hope.',
  ),
  '09-27': WorldDay('World Tourism Day', 'A day for the wonder of elsewhere.'),
  '10-01': WorldDay(
    'Day of Older Persons',
    'Honouring the ones who came before.',
  ),
  '10-02': WorldDay(
    'International Day of Non-Violence',
    'Gandhi\'s birthday — a day for the gentler strength.',
  ),
  '10-05': WorldDay('World Teachers\' Day', 'For everyone who ever taught you something.'),
  '10-10': WorldDay(
    'World Mental Health Day',
    'A day to be kind to your own mind.',
  ),
  '10-16': WorldDay('World Food Day', 'A wish for a table set for everyone.'),
  '11-13': WorldDay(
    'World Kindness Day',
    'A day to do one small good thing.',
  ),
  '11-16': WorldDay('International Day for Tolerance', 'A day for open hearts.'),
  '11-19': WorldDay('International Men\'s Day', 'A day for the men in every life.'),
  '11-20': WorldDay(
    'World Children\'s Day',
    'The world turns toward its youngest.',
  ),
  '12-01': WorldDay('World AIDS Day', 'A day of remembrance and resolve.'),
  '12-03': WorldDay(
    'Day of Persons with Disabilities',
    'A day for a world that fits everyone.',
  ),
  '12-10': WorldDay('Human Rights Day', 'The dignity of every person, affirmed.'),
  '12-20': WorldDay(
    'International Human Solidarity Day',
    'A day for what we owe each other.',
  ),
  '12-25': WorldDay('Christmas Day', 'A day of light and giving for much of the world.'),
};

/// The world observance for [day], or null when the set has no entry — in which
/// case the card simply shows no world line.
WorldDay? worldDayFor(DateTime day) {
  final key =
      '${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  return _worldDays[key];
}
