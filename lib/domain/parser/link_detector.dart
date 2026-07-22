import '../enums.dart';
import 'parsed_task.dart';

/// §5.1 Link detection — regex for known meeting hosts → link + provider.
class LinkDetector {
  static final _patterns = <MeetingProvider, RegExp>{
    MeetingProvider.zoom: RegExp(
      r'https?://[^\s]*zoom\.us/[^\s]+',
      caseSensitive: false,
    ),
    MeetingProvider.teams: RegExp(
      r'https?://teams\.microsoft\.com/[^\s]+',
      caseSensitive: false,
    ),
    MeetingProvider.meet: RegExp(
      r'https?://meet\.google\.com/[^\s]+',
      caseSensitive: false,
    ),
    MeetingProvider.webex: RegExp(
      r'https?://[^\s]*webex\.com/[^\s]+',
      caseSensitive: false,
    ),
  };

  Extracted<({String link, MeetingProvider provider})> detect(String input) {
    for (final entry in _patterns.entries) {
      final match = entry.value.firstMatch(input);
      if (match != null) {
        final span = match.group(0)!;
        return Extracted(
          (link: span, provider: entry.key),
          1.0, // exact host match ⇒ full confidence
          rawSpan: span,
        );
      }
    }
    return Extracted.none();
  }
}
