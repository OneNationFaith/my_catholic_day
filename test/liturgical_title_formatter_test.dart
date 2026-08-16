import 'package:flutter_test/flutter_test.dart';
import 'package:my_catholic_day/services/liturgical_title_formatter.dart';

void main() {
  group('LiturgicalTitleFormatter', () {
    test('removes source-specific USA prefixes', () {
      expect(
        LiturgicalTitleFormatter.format(
          '[USA] Saint Elizabeth Ann Seton, Religious',
        ),
        'Saint Elizabeth Ann Seton, Religious',
      );
    });

    test('normalizes Christmas weekday source wording', () {
      expect(
        LiturgicalTitleFormatter.format(
          'Saturday - Christmas Weekday',
          liturgicalSeason: 'CHRISTMAS',
        ),
        'Saturday of Christmas Time',
      );
    });

    test('normalizes Ordinary Time weekday source wording', () {
      expect(
        LiturgicalTitleFormatter.format(
          'Monday - Ordinary Weekday',
          liturgicalSeason: 'ORDINARY_TIME',
        ),
        'Monday in Ordinary Time',
      );
    });

    test('normalizes Lent weekday source wording', () {
      expect(
        LiturgicalTitleFormatter.format(
          'Tuesday - Lenten Weekday',
          liturgicalSeason: 'LENT',
        ),
        'Tuesday of Lent',
      );
    });

    test('preserves already human-readable celebration titles', () {
      expect(
        LiturgicalTitleFormatter.format(
          'Saints Basil the Great and Gregory Nazianzen, Bishops and Doctors of the Church',
          liturgicalSeason: 'CHRISTMAS',
        ),
        'Saints Basil the Great and Gregory Nazianzen, Bishops and Doctors of the Church',
      );
    });

    test('uses a safe fallback for a missing title', () {
      expect(LiturgicalTitleFormatter.format(null), 'Liturgical Day');
    });
  });
}
