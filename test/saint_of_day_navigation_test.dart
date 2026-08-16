import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_catholic_day/main.dart';
import 'package:my_catholic_day/models/catholic_day.dart';
import 'package:my_catholic_day/screens/saint_detail_screen.dart';
import 'package:my_catholic_day/theme/app_theme.dart';

void main() {
  CatholicDay dayWithSaint(String? saintName) {
    return CatholicDay(
      date: DateTime(2026, 1, 4),
      season: LiturgicalSeason.christmas,
      color: LiturgicalColor.white,
      celebration: 'Saint Elizabeth Ann Seton, Religious',
      rank: CelebrationRank.memorial,
      rosaryMysteries: RosaryMysteries.glorious,
      saintName: saintName,
    );
  }

  Future<void> pumpCard(WidgetTester tester, String? saintName) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: SaintOfDayCard(day: dayWithSaint(saintName))),
      ),
    );
  }

  testWidgets('opens the saint detail screen when a saint is listed', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester, 'Saint Elizabeth Ann Seton');

    expect(find.text('Saint Elizabeth Ann Seton'), findsOneWidget);

    final TextButton learnMore = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Learn More'),
    );
    expect(learnMore.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(TextButton, 'Learn More'));
    await tester.pumpAndSettle();

    expect(find.byType(SaintDetailScreen), findsOneWidget);
    expect(find.text('Saint Elizabeth Ann Seton'), findsOneWidget);
  });

  for (final String? saintName in <String?>[null, '']) {
    testWidgets(
      'disables saint navigation when the saint name is ${saintName == null ? 'null' : 'empty'}',
      (WidgetTester tester) async {
        await pumpCard(tester, saintName);

        expect(find.text('No saint listed today'), findsOneWidget);

        final TextButton learnMore = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Learn More'),
        );
        expect(learnMore.onPressed, isNull);
      },
    );
  }
}
