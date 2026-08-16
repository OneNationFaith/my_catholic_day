import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_catholic_day/models/saint.dart';
import 'package:my_catholic_day/screens/saint_detail_screen.dart';
import 'package:my_catholic_day/theme/app_theme.dart';

void main() {
  Future<void> pumpDetail(WidgetTester tester, Saint saint) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: SaintDetailScreen(saint: saint),
      ),
    );
  }

  testWidgets('displays all populated saint content except source metadata', (
    WidgetTester tester,
  ) async {
    const Saint saint = Saint(
      id: 'complete-saint',
      displayName: 'Complete Saint',
      feastMonth: 1,
      feastDay: 4,
      shortBiography: 'Complete biography.',
      patronages: <String>['First patronage', 'Second patronage'],
      birthInformation: SaintLifeInformation(
        date: 'Birth date',
        place: 'Birth place',
        notes: 'Birth notes.',
      ),
      deathInformation: SaintLifeInformation(
        date: 'Death date',
        place: 'Death place',
        notes: 'Death notes.',
      ),
      saintType: 'Martyr',
      shortReflection: 'Short reflection.',
      prayer: 'Short prayer.',
      sources: <SaintSourceReference>[
        SaintSourceReference(
          label: 'Hidden source',
          attribution: 'Hidden attribution',
        ),
      ],
    );

    await pumpDetail(tester, saint);

    expect(find.text('Complete Saint'), findsOneWidget);
    expect(find.text('Feast Day • January 4'), findsOneWidget);
    expect(find.text('Martyr'), findsOneWidget);
    expect(find.text('Biography'), findsOneWidget);
    expect(find.text('Complete biography.'), findsOneWidget);
    expect(find.text('Patronages'), findsOneWidget);
    expect(find.text('First patronage'), findsOneWidget);
    expect(find.text('Second patronage'), findsOneWidget);
    expect(find.text('Birth'), findsOneWidget);
    expect(find.text('Date: Birth date'), findsOneWidget);
    expect(find.text('Place: Birth place'), findsOneWidget);
    expect(find.text('Birth notes.'), findsOneWidget);
    expect(find.text('Death'), findsOneWidget);
    expect(find.text('Date: Death date'), findsOneWidget);
    expect(find.text('Place: Death place'), findsOneWidget);
    expect(find.text('Death notes.'), findsOneWidget);
    expect(find.text('Reflection'), findsOneWidget);
    expect(find.text('Short reflection.'), findsOneWidget);
    expect(find.text('Prayer'), findsOneWidget);
    expect(find.text('Short prayer.'), findsOneWidget);
    expect(find.text('Hidden source'), findsNothing);
    expect(find.text('Hidden attribution'), findsNothing);
  });

  testWidgets('omits headings for absent optional saint content', (
    WidgetTester tester,
  ) async {
    const Saint saint = Saint(
      id: 'minimal-saint',
      displayName: 'Minimal Saint',
      feastMonth: 2,
      feastDay: 29,
      shortBiography: 'Minimal biography.',
      patronages: <String>[],
      sources: <SaintSourceReference>[
        SaintSourceReference(label: 'Hidden source'),
      ],
    );

    await pumpDetail(tester, saint);

    expect(find.text('Minimal Saint'), findsOneWidget);
    expect(find.text('Feast Day • February 29'), findsOneWidget);
    expect(find.text('Minimal biography.'), findsOneWidget);
    expect(find.text('Patronages'), findsNothing);
    expect(find.text('Birth'), findsNothing);
    expect(find.text('Death'), findsNothing);
    expect(find.text('Reflection'), findsNothing);
    expect(find.text('Prayer'), findsNothing);
    expect(find.text('Hidden source'), findsNothing);
  });
}
