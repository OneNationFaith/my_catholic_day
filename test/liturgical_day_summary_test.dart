import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_catholic_day/models/catholic_day.dart';
import 'package:my_catholic_day/theme/app_theme.dart';
import 'package:my_catholic_day/widgets/liturgical_day_summary.dart';

void main() {
  Future<void> pumpSummary(WidgetTester tester, CatholicDay day) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: LiturgicalDaySummary(day: day)),
      ),
    );
  }

  group('LiturgicalDaySummary UI', () {
    testWidgets(
      'shows a Holy Day of Obligation label when the model requires it',
      (WidgetTester tester) async {
        final CatholicDay day = CatholicDay(
          date: DateTime(2026, 5, 14),
          season: LiturgicalSeason.easter,
          color: LiturgicalColor.white,
          celebration: 'Ascension',
          rank: CelebrationRank.solemnity,
          rosaryMysteries: RosaryMysteries.luminous,
          isHolyDayOfObligation: true,
        );

        await pumpSummary(tester, day);

        expect(find.text('Ascension'), findsOneWidget);
        expect(
          find.text('Easter â€¢ White â€¢ Luminous Mysteries'),
          findsOneWidget,
        );
        expect(find.text('Holy Day of Obligation'), findsOneWidget);
      },
    );

    testWidgets(
      'omits the Holy Day of Obligation label when the model does not require it',
      (WidgetTester tester) async {
        final CatholicDay day = CatholicDay(
          date: DateTime(2026, 8, 15),
          season: LiturgicalSeason.ordinaryTime,
          color: LiturgicalColor.white,
          celebration: 'Assumption of the Blessed Virgin Mary',
          rank: CelebrationRank.solemnity,
          rosaryMysteries: RosaryMysteries.joyful,
          isHolyDayOfObligation: false,
        );

        await pumpSummary(tester, day);

        expect(
          find.text('Assumption of the Blessed Virgin Mary'),
          findsOneWidget,
        );
        expect(find.text('Holy Day of Obligation'), findsNothing);
      },
    );
  });
}
