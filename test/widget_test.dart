import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:authorization_mobile/config/backends.dart';
import 'package:authorization_mobile/screens/splash_screen.dart';

void main() {
  // SplashScreen has a repeat animation (_floatController) so pumpAndSettle
  // would time out — use pump(Duration) instead.
  testWidgets('SplashScreen shows scan button and backend selector', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          onStart: () {},
          selectedBackend: kDefaultBackend,
          onSelectBackend: (_) async {},
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('QRコードをスキャン'), findsOneWidget);
    expect(find.text('Backend:'), findsOneWidget);
    expect(find.text('PHP'), findsOneWidget);
  });
}
