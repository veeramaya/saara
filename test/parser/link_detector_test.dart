import 'package:flutter_test/flutter_test.dart';
import 'package:saara/domain/enums.dart';
import 'package:saara/domain/parser/link_detector.dart';

void main() {
  final detector = LinkDetector();

  group('meeting link detection (§5.1)', () {
    test('zoom', () {
      final r = detector.detect('sync https://acme.zoom.us/j/123 at 3pm');
      expect(r.value?.provider, MeetingProvider.zoom);
      expect(r.value?.link, 'https://acme.zoom.us/j/123');
    });
    test('google meet', () {
      final r = detector.detect('standup https://meet.google.com/abc-defg-hij');
      expect(r.value?.provider, MeetingProvider.meet);
    });
    test('teams', () {
      final r = detector.detect(
        'review https://teams.microsoft.com/l/meetup-join/x',
      );
      expect(r.value?.provider, MeetingProvider.teams);
    });
    test('no link → none', () {
      expect(detector.detect('buy milk').isPresent, isFalse);
    });
  });
}
