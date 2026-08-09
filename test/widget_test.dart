import 'package:flutter_test/flutter_test.dart';
import 'package:my_catholic_day/main.dart';

void main() {
  testWidgets('One Nation Faith app builds', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const OneNationFaithApp(),
    );

    await tester.pump(
      const Duration(seconds: 3),
    );

    expect(
      find.byType(OneNationFaithApp),
      findsOneWidget,
    );
  });
}