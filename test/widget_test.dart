import 'package:flutter_test/flutter_test.dart';

import 'package:bot_detection_app/main.dart';

void main() {
  testWidgets('App launches correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BotDetectionApp());

    // Verify that our app launches
    expect(find.text('Bot Detection Dataset Selection'), findsOneWidget);
  });
}