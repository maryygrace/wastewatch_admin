// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:flutter_test/flutter_test.dart';

import 'package:wastewatch_admin/main.dart';

void main() {
  testWidgets('AdminHomePage has a title and welcome message', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We need to wrap WasteWatchAdminApp in a test harness that can initialize Supabase.
    // For now, we will just test the UI.
    await tester.pumpWidget(const WasteWatchAdminApp());

    // Verify that the title and body text are present.
    expect(find.text('WasteWatch Admin Dashboard'), findsOneWidget);
    expect(find.text('Welcome to the WasteWatch Admin Panel!'), findsOneWidget);
  });
}
