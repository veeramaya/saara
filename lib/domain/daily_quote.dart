/// Bundled, public-domain quotes for the daily ritual (§ Open/Close your day).
///
/// Local-first: the set ships in the app and the day's quote is chosen
/// **deterministically from the date**, so every device shows the same one and
/// it costs nothing to sync (it's static content, not data). The morning set
/// energises; the evening set reflects and completes.
///
/// Attributions are kept to well-known, public-domain sayings. Where a source
/// is uncertain it's marked as a proverb rather than mis-attributed.
class DailyQuote {
  const DailyQuote(this.text, this.author);
  final String text;
  final String author;
}

/// Energising, integrity-minded quotes to open the day.
const List<DailyQuote> kMorningQuotes = <DailyQuote>[
  DailyQuote('Well begun is half done.', 'Aristotle'),
  DailyQuote('Either you run the day, or the day runs you.', 'Jim Rohn'),
  DailyQuote('The secret of getting ahead is getting started.', 'Mark Twain'),
  DailyQuote('Quality is not an act, it is a habit.', 'Aristotle'),
  DailyQuote('Do the difficult things while they are easy.', 'Lao Tzu'),
  DailyQuote(
    'When you arise in the morning, think of what a privilege it is to be alive.',
    'Marcus Aurelius',
  ),
  DailyQuote(
    'The way to get started is to quit talking and begin doing.',
    'Walt Disney',
  ),
  DailyQuote(
    'First say to yourself what you would be; and then do what you have to do.',
    'Epictetus',
  ),
  DailyQuote(
    'Discipline is the bridge between goals and accomplishment.',
    'Jim Rohn',
  ),
  DailyQuote(
    'Begin at once to live, and count each day as a separate life.',
    'Seneca',
  ),
  DailyQuote(
    'The best preparation for tomorrow is doing your best today.',
    'H. Jackson Brown Jr.',
  ),
  DailyQuote('Small deeds done are better than great deeds planned.', 'Peter Marshall'),
  DailyQuote('He who has a why to live can bear almost any how.', 'Friedrich Nietzsche'),
  DailyQuote('Lose an hour in the morning, and you hunt for it all day.', 'Richard Whately'),
  DailyQuote('A journey of a thousand miles begins with a single step.', 'Lao Tzu'),
  DailyQuote('It always seems impossible until it is done.', 'Proverb'),
  DailyQuote('What you do today can improve all your tomorrows.', 'Ralph Marston'),
  DailyQuote('Action is the foundational key to all success.', 'Pablo Picasso'),
];

/// Reflective quotes to close and complete the day.
const List<DailyQuote> kEveningQuotes = <DailyQuote>[
  DailyQuote(
    'Finish each day and be done with it. You have done what you could.',
    'Ralph Waldo Emerson',
  ),
  DailyQuote(
    'How we spend our days is, of course, how we spend our lives.',
    'Annie Dillard',
  ),
  DailyQuote('The unexamined life is not worth living.', 'Socrates'),
  DailyQuote(
    'He who lives in harmony with himself lives in harmony with the world.',
    'Marcus Aurelius',
  ),
  DailyQuote('Do not spoil what you have by desiring what you have not.', 'Epictetus'),
  DailyQuote('What lies in our power to do, lies in our power not to do.', 'Aristotle'),
  DailyQuote('A clear conscience is a soft pillow.', 'Proverb'),
  DailyQuote('Rest when you are weary; renew yourself.', 'Ralph Marston'),
  DailyQuote(
    'Every night I die, and every morning I am reborn.',
    'Mahatma Gandhi',
  ),
  DailyQuote('When you have done your best, you have done enough.', 'Proverb'),
  DailyQuote(
    'No man is free who is not master of himself.',
    'Epictetus',
  ),
  DailyQuote('The day is done, and its lesson is learned.', 'Proverb'),
  DailyQuote('Look well to this day, for it is life.', 'Kalidasa'),
  DailyQuote('Peace begins with a completed day.', 'Proverb'),
  DailyQuote('Tomorrow is a new day; begin it well and serenely.', 'Ralph Waldo Emerson'),
];

/// The quote for [day]. Deterministic by the date so every device agrees and it
/// rotates without repeating for the length of the set.
DailyQuote quoteForDay(DateTime day, {required bool morning}) {
  final list = morning ? kMorningQuotes : kEveningQuotes;
  // Days since the Unix epoch — stable per calendar day, independent of time.
  final index = (day.toUtc().difference(DateTime.utc(1970)).inDays) % list.length;
  return list[index.abs()];
}
