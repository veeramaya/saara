/// §13 reliability ladder. Task scoring is binary (done = 1, not-done = 0). The
/// summary metric is *effectiveness* = kept ÷ committed, expressed 0..100, and
/// mapped to a named level — the platform's real aim is to move the user up it,
/// from someone learning to keep their word to someone whose word is trusted.
class ReliabilityLevel {
  const ReliabilityLevel(this.maxPct, this.name, this.blurb);

  /// Inclusive upper bound of this band (percent).
  final int maxPct;
  final String name;
  final String blurb;
}

/// Six tiers. The summit is split (Champion 71–85 / Masterful 86–100) because
/// trust only consolidates at high consistency — people remember the misses.
const kReliabilityLevels = <ReliabilityLevel>[
  ReliabilityLevel(
    10,
    'Beginner',
    "Just starting — your word isn't a habit yet.",
  ),
  ReliabilityLevel(
    30,
    'Learner',
    'Building the muscle; misses are still common.',
  ),
  ReliabilityLevel(50, 'Amateur', 'You keep some words — consistency wavers.'),
  ReliabilityLevel(70, 'Professional', 'Dependable more often than not.'),
  ReliabilityLevel(85, 'Champion', 'Highly reliable — trusted in most things.'),
  ReliabilityLevel(
    100,
    'Masterful',
    'Your word is your bond — trusted without question.',
  ),
];

/// The level name for an effectiveness percentage (0..100).
String reliabilityLevelName(double pct) {
  for (final l in kReliabilityLevels) {
    if (pct <= l.maxPct) return l.name;
  }
  return kReliabilityLevels.last.name;
}

/// Overall effectiveness from per-area (kept, committed) tallies, 0..100.
/// Returns 0 when nothing has been committed yet.
double overallEffectiveness(Iterable<({int kept, int committed})> areas) {
  var k = 0, c = 0;
  for (final a in areas) {
    k += a.kept;
    c += a.committed;
  }
  return c == 0 ? 0 : k / c * 100;
}
