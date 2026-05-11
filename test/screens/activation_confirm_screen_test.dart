import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:authorization_mobile/models/client_info.dart';
import 'package:authorization_mobile/screens/activation_confirm_screen.dart';

void main() {
  const testClient = ClientInfo(
    name: '株式会社テスト',
    identifier: 'client_test_001',
    email: 'test@example.com',
    status: ClientStatus.preparing,
  );

  Widget buildSubject({
    VoidCallback? onActivate,
    VoidCallback? onBack,
  }) {
    return MaterialApp(
      home: ActivationConfirmScreen(
        clientInfo: testClient,
        onActivate: onActivate ?? () {},
        onBack: onBack ?? () {},
      ),
    );
  }

  testWidgets('shows header title', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('利用開始の確認'), findsOneWidget);
  });

  testWidgets('shows client name, identifier, and email', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('株式会社テスト'), findsOneWidget);
    expect(find.text('client_test_001'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
  });

  testWidgets('shows status label', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('準備中'), findsOneWidget);
  });

  testWidgets('activate button calls onActivate', (tester) async {
    var activated = false;
    await tester.pumpWidget(buildSubject(onActivate: () => activated = true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('利用開始する'));
    expect(activated, isTrue);
  });

  testWidgets('back button calls onBack', (tester) async {
    var wentBack = false;
    await tester.pumpWidget(buildSubject(onBack: () => wentBack = true));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(wentBack, isTrue);
  });
}
