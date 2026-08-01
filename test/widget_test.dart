// Basic smoke test for the Tasbih app.
//
// It verifies the app builds and shows the splash screen without throwing.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tasbih_app/main.dart';

void main() {
  testWidgets('App builds and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TasbihApp(),
      ),
    );

    expect(find.text('عداد التسبيح'), findsOneWidget);

    // Splash screen auto-navigates after a delay; flush that timer so no
    // pending timers remain when the test tears down.
    await tester.pump(const Duration(seconds: 3));
  });
}
