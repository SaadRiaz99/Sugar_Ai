import 'package:flutter_test/flutter_test.dart';
import 'package:sugar_ai/app.dart';

void main() {
  testWidgets('App launches and shows login screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SugarAIApp());
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
