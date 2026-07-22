import '../enums.dart';
import 'date_grammar.dart';
import 'link_detector.dart';
import 'parsed_task.dart';

/// §5 Deterministic parser (Tier 0 NLP). Runs the full pipeline over raw input
/// (typed text or share-target extraction) and returns a [ParsedTaskDraft].
///
/// Steps 3 (participants → on-device contacts) and 4 (location → saved places)
/// need device data that arrives in Phase 2 (§11, §17); they are represented
/// here as low-confidence heuristics and flagged for the card. Steps 1, 2, 5, 6
/// are fully deterministic and complete.
class DeterministicParser {
  DeterministicParser({DateTime Function()? clock})
    : _grammar = DateGrammar(clock: clock);

  final DateGrammar _grammar;
  final LinkDetector _links = LinkDetector();

  /// §5.5 area keyword dictionary (user-extendable in a later phase). Maps a
  /// keyword → base category. Kept small and obvious; extend per feedback.
  static const Map<String, BaseCategory> _areaKeywords = {
    'gym': BaseCategory.health,
    'walk': BaseCategory.health,
    'run': BaseCategory.health,
    'doctor': BaseCategory.health,
    'workout': BaseCategory.health,
    'meditate': BaseCategory.health,
    'family': BaseCategory.family,
    'kids': BaseCategory.family,
    'mom': BaseCategory.family,
    'dad': BaseCategory.family,
    'pay': BaseCategory.finance,
    'bill': BaseCategory.finance,
    'invoice': BaseCategory.finance,
    'budget': BaseCategory.finance,
    'bank': BaseCategory.finance,
    'meeting': BaseCategory.work,
    'email': BaseCategory.work,
    'report': BaseCategory.work,
    'standup': BaseCategory.work,
    'deploy': BaseCategory.work,
    'call': BaseCategory.relationships,
    'coffee': BaseCategory.relationships,
    'dinner': BaseCategory.relationships,
  };

  ParsedTaskDraft parse(String input, {TaskSource source = TaskSource.manual}) {
    final confidence = <String, double>{};
    final consumedSpans = <String>[];

    // 1. Link detection
    final link = _links.detect(input);
    if (link.isPresent) {
      confidence['meetingLink'] = link.confidence;
      if (link.rawSpan != null) consumedSpans.add(link.rawSpan!);
    }

    // 2. Date / time / duration / recurrence
    final when = _grammar.dateTimeOf(input);
    if (when.isPresent) {
      confidence['scheduledStart'] = when.confidence;
      if (when.rawSpan != null) consumedSpans.add(when.rawSpan!);
    }
    final dur = _grammar.duration(input);
    if (dur.isPresent) {
      confidence['durationMin'] = dur.confidence;
      if (dur.rawSpan != null) consumedSpans.add(dur.rawSpan!);
    }
    final recur = _grammar.recurrence(input);
    if (recur.isPresent) {
      confidence['rrule'] = recur.confidence;
      if (recur.rawSpan != null) consumedSpans.add(recur.rawSpan!);
    }

    // 5. Area guess (keyword dictionary)
    final area = _guessArea(input);
    if (area != null) confidence['area'] = 0.7;

    // 6. Title = input minus consumed tokens, cleaned.
    final title = _buildTitle(input, consumedSpans);
    confidence['title'] = title.isEmpty ? 0.0 : 0.9;

    return ParsedTaskDraft(
      title: title.isEmpty ? input.trim() : title,
      rawInput: input,
      scheduledStart: when.value,
      durationMin: dur.value,
      rrule: recur.value,
      meetingLink: link.value?.link,
      meetingProvider: link.value?.provider,
      areaGuess: area,
      fieldConfidence: confidence,
      source: source,
    );
  }

  BaseCategory? _guessArea(String input) {
    final lower = input.toLowerCase();
    for (final entry in _areaKeywords.entries) {
      if (RegExp('\\b${entry.key}\\b').hasMatch(lower)) return entry.value;
    }
    return null;
  }

  String _buildTitle(String input, List<String> consumed) {
    var title = input;
    for (final span in consumed) {
      title = title.replaceAll(
        RegExp(RegExp.escape(span), caseSensitive: false),
        ' ',
      );
    }
    // Strip filler prepositions left dangling by removed spans.
    title = title
        .replaceAll(
          RegExp(r'\b(for|at|on|to|in)\b\s*$', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return title;
  }
}
