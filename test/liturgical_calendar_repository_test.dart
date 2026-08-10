import 'package:flutter_test/flutter_test.dart';
import 'package:my_catholic_day/data/liturgical_calendar_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const LiturgicalCalendarRepository repository =
      LiturgicalCalendarRepository();

  group('LiturgicalCalendarRepository 2026', () {
    test('uses Sunday Ascension by default', () async {
      final ResolvedLiturgicalCalendarDay may14 =
          await repository.getForDate(DateTime(2026, 5, 14));

      final ResolvedLiturgicalCalendarDay may17 =
          await repository.getForDate(DateTime(2026, 5, 17));

      expect(
        may14.primaryEvent['event_key'],
        'StMatthiasAp',
      );
      expect(
        may17.primaryEvent['event_key'],
        'Ascension',
      );
      expect(
        may14.usedAscensionThursdayVariant,
        isFalse,
      );
      expect(
        may17.usedAscensionThursdayVariant,
        isFalse,
      );
    });

    test('uses Thursday Ascension in New York', () async {
      final ResolvedLiturgicalCalendarDay may14 =
          await repository.getForDate(
        DateTime(2026, 5, 14),
        stateCode: 'NY',
      );

      final ResolvedLiturgicalCalendarDay may17 =
          await repository.getForDate(
        DateTime(2026, 5, 17),
        stateCode: 'NY',
      );

      expect(
        may14.primaryEvent['event_key'],
        'Ascension',
      );
      expect(
        may17.primaryEvent['event_key'],
        'Easter7',
      );
      expect(
        may14.usedAscensionThursdayVariant,
        isTrue,
      );
      expect(
        may17.usedAscensionThursdayVariant,
        isTrue,
      );
    });

    test('normalizes June 13 USCCB calendar choices', () async {
      final ResolvedLiturgicalCalendarDay day =
          await repository.getForDate(DateTime(2026, 6, 13));

      expect(
        day.primaryEvent['event_key'],
        'ONF_USCCB_2026_06_13_WEEKDAY',
      );

      final Set<String> optionalKeys = day.optionalMemorials
          .map(
            (Map<String, dynamic> event) =>
                event['event_key']?.toString() ?? '',
          )
          .toSet();

      expect(
        optionalKeys,
        containsAll(<String>[
          'ImmaculateHeart',
          'StAnthonyPadua',
          'ONF_USCCB_2026_06_13_BVM',
        ]),
      );
    });

    test('abrogates 2026 Assumption obligation', () async {
      final ResolvedLiturgicalCalendarDay day =
          await repository.getForDate(DateTime(2026, 8, 15));

      expect(
        day.primaryEvent['event_key'],
        'Assumption',
      );
      expect(
        day.primaryEvent['holy_day_of_obligation'],
        isFalse,
      );
    });
  });
}
