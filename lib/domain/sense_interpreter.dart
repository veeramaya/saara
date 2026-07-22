/// §5/§6 sense interpreter — a deterministic keyword→sense map used to pick the
/// contextual completion/loader animation for a task. No AI: same input, same
/// sense, every time. Falls back to "word" (the spoken commitment).
enum SenseKind { sound, taste, touch, smell, sight, word }

class _SenseRule {
  const _SenseRule(this.kind, this.words);
  final SenseKind kind;
  final List<String> words;
}

const _rules = <_SenseRule>[
  _SenseRule(SenseKind.sound, [
    'meet',
    'call',
    'convers',
    'talk',
    'discuss',
    'present',
    'email',
    'message',
    'sync',
    'standup',
    'interview',
    'teach',
    'chat',
    'pitch',
  ]),
  _SenseRule(SenseKind.taste, [
    'eat',
    'lunch',
    'dinner',
    'breakfast',
    'meal',
    'snack',
    'drink',
    'fruit',
    'grocery',
    'diet',
    'feast',
  ]),
  _SenseRule(SenseKind.touch, [
    'walk',
    'run',
    'gym',
    'exercise',
    'workout',
    'yoga',
    'stretch',
    'clean',
    'laundry',
    'commute',
    'travel',
    'dance',
    'sport',
    'jog',
    'hike',
    'swim',
  ]),
  _SenseRule(SenseKind.smell, [
    'cook',
    'bake',
    'bath',
    'shower',
    'coffee',
    'tea',
    'garden',
    'flower',
    'wash',
    'brew',
  ]),
  _SenseRule(SenseKind.sight, [
    'read',
    'watch',
    'design',
    'paint',
    'draw',
    'review',
    'study',
    'movie',
    'photo',
    'plan',
    'write',
    'code',
  ]),
];

/// The sense a task's title/notes evoke (§5). Case-insensitive substring match.
SenseKind senseForTask(String text) {
  final t = text.toLowerCase();
  for (final r in _rules) {
    for (final w in r.words) {
      if (t.contains(w)) return r.kind;
    }
  }
  return SenseKind.word;
}
