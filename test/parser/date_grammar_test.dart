import 'package:flutter_test/flutter_test.dart';
import 'package:saara/domain/parser/date_grammar.dart';

void main() {
  // Fixed clock: Wednesday, 2026-07-15 09:00 local.
  DateTime fixedNow() => DateTime(2026, 7, 15, 9);
  final grammar = DateGrammar(clock: fixedNow);

  group('duration (§6)', () {
    test('"for 45 min" → 45', () {
      expect(grammar.duration('call for 45 min').value, 45);
    });
    test('"1.5 hr" → 90', () {
      expect(grammar.duration('meeting 1.5 hr').value, 90);
    });
    test('"half an hour" → 30', () {
      expect(grammar.duration('walk for half an hour').value, 30);
    });
    test('"45m" → 45', () {
      expect(grammar.duration('45m standup').value, 45);
    });
  });

  group('recurrence → RRULE (§6)', () {
    test('daily', () {
      expect(grammar.recurrence('every day').value, 'FREQ=DAILY');
    });
    test('weekdays', () {
      expect(
        grammar.recurrence('gym weekdays').value,
        'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
      );
    });
    test('weekends', () {
      expect(
        grammar.recurrence('brunch weekends').value,
        'FREQ=WEEKLY;BYDAY=SA,SU',
      );
    });
    test('every other tue', () {
      expect(
        grammar.recurrence('sync every other tue').value,
        'FREQ=WEEKLY;INTERVAL=2;BYDAY=TU',
      );
    });
    test('1st monday of month', () {
      expect(
        grammar.recurrence('board 1st monday of month').value,
        'FREQ=MONTHLY;BYDAY=1MO',
      );
    });
  });

  group('relative date/time (§6)', () {
    test('tonight = 20:00', () {
      final d = grammar.dateTimeOf('call mom tonight').value!;
      expect(d, DateTime(2026, 7, 15, 20));
    });
    test('tomorrow', () {
      final d = grammar.dateTimeOf('dentist tomorrow').value!;
      expect(d, DateTime(2026, 7, 16));
    });
    test('in 3 days', () {
      final d = grammar.dateTimeOf('pay rent in 3 days').value!;
      expect(d, DateTime(2026, 7, 18));
    });
    test('next fri picks the upcoming Friday', () {
      final d = grammar.dateTimeOf('review next fri').value!;
      expect(d.weekday, DateTime.friday);
      expect(d.isAfter(fixedNow()), isTrue);
    });
    test('tomorrow at 7am layers the clock time', () {
      final d = grammar.dateTimeOf('walk tomorrow at 7am').value!;
      expect(d, DateTime(2026, 7, 16, 7));
    });
  });
}
