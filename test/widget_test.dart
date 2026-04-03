import 'package:flutter_test/flutter_test.dart';

import 'package:g13money/app/app.dart';

void main() {
  testWidgets('Login screen is shown on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpenseManagerApp());

    final vietnameseLoginCount = find.text('Đăng nhập').evaluate().length;
    final englishLoginCount = find.text('Sign in').evaluate().length;

    expect(vietnameseLoginCount + englishLoginCount, greaterThanOrEqualTo(1));
    expect(find.text('G13 Money'), findsOneWidget);
  });
}
