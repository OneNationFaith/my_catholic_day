import 'package:flutter_test/flutter_test.dart';
import 'package:my_catholic_day/models/catholic_day.dart';
import 'package:my_catholic_day/services/catholic_day_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CatholicDayService 2026 calendar-to-model mapping', () {
    test('maps New York Ascension Thursday for the Today UI model', () async {
      const CatholicDayService service = CatholicDayService(stateCode: 'NY');

      final CatholicDay day = await service.getForDate(DateTime(2026, 5, 14));

      expect(day.celebration, 'Ascension');
      expect(day.season, LiturgicalSeason.easter);
      expect(day.color, LiturgicalColor.white);
      expect(day.rank, CelebrationRank.solemnity);
      expect(day.isHolyDayOfObligation, isTrue);
    });

    test('uses the national calendar when no state is saved', () async {
      const CatholicDayService service = CatholicDayService();

      final CatholicDay day = await service.getForDate(DateTime(2026, 5, 14));

      expect(day.celebration, isNot('Ascension'));
      expect(day.isHolyDayOfObligation, isFalse);
    });

    test('maps the 2026 Assumption without an obligation label', () async {
      const CatholicDayService service = CatholicDayService();

      final CatholicDay day = await service.getForDate(DateTime(2026, 8, 15));

      expect(day.celebration, contains('Assumption'));
      expect(day.rank, CelebrationRank.solemnity);
      expect(day.isHolyDayOfObligation, isFalse);
    });
  });
}
