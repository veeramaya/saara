import '../enums.dart';

/// A single extracted field plus the extractor's confidence (0–1, §5).
class Extracted<T> {
  const Extracted(this.value, this.confidence, {this.rawSpan});
  final T? value;
  final double confidence;

  /// The substring consumed from the input, so the title builder can strip it.
  final String? rawSpan;

  bool get isPresent => value != null;
  static Extracted<T> none<T>() => Extracted<T>(null, 0);
}

/// The structured draft produced by the deterministic parser (§5). This is the
/// pre-filled task card (§7.2); fields below [confidenceThreshold] are
/// highlighted as uncertain and never auto-saved (§5 "Never create a task
/// silently from low-confidence parse").
class ParsedTaskDraft {
  ParsedTaskDraft({
    required this.title,
    required this.rawInput,
    this.scheduledStart,
    this.durationMin,
    this.dueDate,
    this.rrule,
    this.meetingLink,
    this.meetingProvider,
    this.locationName,
    this.areaGuess,
    this.participants = const [],
    required this.fieldConfidence,
    required this.source,
  });

  /// Composite confidence below which the card shows uncertain-field highlights
  /// and offers "Ask Saara" (Tier 1) / quick-fill chips (§5).
  static const double confidenceThreshold = 0.6;

  final String title;
  final String rawInput;

  final DateTime? scheduledStart;
  final int? durationMin;
  final DateTime? dueDate;
  final String? rrule; // iCalendar RRULE (§6)

  final String? meetingLink;
  final MeetingProvider? meetingProvider;

  final String? locationName;

  /// Base category keyword guess; low confidence ⇒ leave unassigned (§5.5).
  final BaseCategory? areaGuess;

  /// Contact display-name tokens that matched (resolution to lookup keys is
  /// Phase 2 once contacts are wired, §11).
  final List<String> participants;

  /// Per-field confidence, keyed by a stable field name.
  final Map<String, double> fieldConfidence;

  final TaskSource source;

  /// Composite confidence = mean of the present fields' scores (§5).
  double get compositeConfidence {
    if (fieldConfidence.isEmpty) return 0;
    final total = fieldConfidence.values.fold<double>(0, (a, b) => a + b);
    return total / fieldConfidence.length;
  }

  bool get needsReview => compositeConfidence < confidenceThreshold;

  /// Field names whose confidence is below threshold — the card highlights these.
  List<String> get uncertainFields => [
    for (final e in fieldConfidence.entries)
      if (e.value < confidenceThreshold) e.key,
  ];
}
