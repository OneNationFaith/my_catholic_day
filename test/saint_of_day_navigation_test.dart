import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_catholic_day/data/repositories/saint_repository.dart';
import 'package:my_catholic_day/main.dart';
import 'package:my_catholic_day/models/saint.dart';
import 'package:my_catholic_day/screens/saint_detail_screen.dart';
import 'package:my_catholic_day/theme/app_theme.dart';

void main() {
  Future<_TestSaintRepository> pumpCard(
    WidgetTester tester,
    List<Saint> saints, {
    DateTime? date,
    Object? error,
  }) async {
    final _TestSaintRepository repository = _TestSaintRepository(
      saints,
      error: error,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SaintOfDayCard(
            date: date ?? DateTime(2030, 1, 4),
            repository: repository,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('shows an empty state when no devotional saint is listed', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester, const <Saint>[]);

    expect(find.text('No saint listed today'), findsOneWidget);

    final TextButton learnMore = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Learn More'),
    );
    expect(learnMore.onPressed, isNull);
  });

  testWidgets('uses the supplied date and opens the single saint', (
    WidgetTester tester,
  ) async {
    final _TestSaintRepository repository = await pumpCard(tester, <Saint>[
      _testSaint('elizabeth-ann-seton', 'Saint Elizabeth Ann Seton'),
    ], date: DateTime(2035, 1, 4));

    expect(find.text('Saint Elizabeth Ann Seton'), findsOneWidget);
    expect(repository.requestedMonth, 1);
    expect(repository.requestedDay, 4);

    final TextButton learnMore = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Learn More'),
    );
    expect(learnMore.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(TextButton, 'Learn More'));
    await tester.pumpAndSettle();

    expect(find.byType(SaintDetailScreen), findsOneWidget);
    expect(find.text('Saint Elizabeth Ann Seton'), findsOneWidget);
  });

  testWidgets('offers every matching saint for selection', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester, <Saint>[
      _testSaint('first-saint', 'First Saint'),
      _testSaint('second-saint', 'Second Saint'),
    ]);

    expect(find.text('2 saints listed today'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Learn More'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a Saint'), findsOneWidget);
    expect(find.text('First Saint'), findsOneWidget);
    expect(find.text('Second Saint'), findsOneWidget);

    await tester.tap(find.text('Second Saint'));
    await tester.pumpAndSettle();

    expect(find.byType(SaintDetailScreen), findsOneWidget);
    expect(find.text('Second Saint'), findsOneWidget);
  });

  testWidgets('keeps repository errors inside the saint card', (
    WidgetTester tester,
  ) async {
    await pumpCard(
      tester,
      const <Saint>[],
      error: StateError('Test repository failure'),
    );

    expect(find.text('Unable to load saint information'), findsOneWidget);

    final TextButton learnMore = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Learn More'),
    );
    expect(learnMore.onPressed, isNull);
  });
}

Saint _testSaint(String id, String displayName) {
  return Saint(
    id: id,
    displayName: displayName,
    feastMonth: 1,
    feastDay: 4,
    shortBiography: 'Test biography.',
    patronages: const <String>[],
    sources: const <SaintSourceReference>[
      SaintSourceReference(label: 'Test source'),
    ],
  );
}

class _TestSaintRepository extends SaintRepository {
  _TestSaintRepository(this.saints, {this.error});

  final List<Saint> saints;
  final Object? error;

  int? requestedMonth;
  int? requestedDay;

  @override
  Future<List<Saint>> getByFeastDate({
    required int month,
    required int day,
  }) async {
    requestedMonth = month;
    requestedDay = day;

    final Object? lookupError = error;

    if (lookupError != null) {
      throw lookupError;
    }

    return saints;
  }
}
