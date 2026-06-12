import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lari_lari/main.dart';
import 'package:lari_lari/features/auth/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('App starts with SplashScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: LariLariApp()));

    // Verify that SplashScreen is present.
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
