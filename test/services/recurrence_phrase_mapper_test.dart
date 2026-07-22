import 'package:flutter_test/flutter_test.dart';
import 'package:saara/services/import/recurrence_phrase_mapper.dart';

void main() {
  const mapper = RecurrencePhraseMapper();

  group('repeat phrase → RRULE', () {
    test('every day', () => expect(mapper.toRrule('every day'), 'FREQ=DAILY'));
    test('daily', () => expect(mapper.toRrule('Daily'), 'FREQ=DAILY'));
    test('weekdays', () {
      expect(mapper.toRrule('weekdays'), 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR');
    });
    test('every mon, wed', () {
      expect(mapper.toRrule('every mon, wed'), 'FREQ=WEEKLY;BYDAY=MO,WE');
    });
    test('every 2 weeks', () {
      expect(mapper.toRrule('every 2 weeks'), 'FREQ=WEEKLY;INTERVAL=2');
    });
    test('unmappable → null (imports as non-recurring)', () {
      expect(mapper.toRrule('every last workday'), isNull);
    });
    test('empty / null → null', () {
      expect(mapper.toRrule(''), isNull);
      expect(mapper.toRrule(null), isNull);
    });
  });
}
