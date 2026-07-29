import 'package:flutter_test/flutter_test.dart';
import 'package:my_catholic_day/main.dart';

void main() {
  testWidgets('My Catholic Day app builds', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MyCatholicDayApp(),
    );

    expect(
      find.byType(MyCatholicDayApp),
      findsOneWidget,
    );
  });
}