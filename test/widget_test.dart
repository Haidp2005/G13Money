import 'package:flutter_test/flutter_test.dart';

import 'package:g13money/app/app.dart';

void main() {
  testWidgets('Login screen is shown on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpenseManagerApp());

    expect(find.text('Dang nhap'), findsNWidgets(2));
    expect(find.text('G13 Money'), findsOneWidget);
  });
}
