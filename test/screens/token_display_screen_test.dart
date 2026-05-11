import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:authorization_mobile/screens/token_display_screen.dart';

void main() {
  const testToken = 'sk_live_test_token_abc123';
  const testClientName = '株式会社テスト';

  Widget buildSubject({VoidCallback? onClose}) {
    return MaterialApp(
      home: TokenDisplayScreen(
        token: testToken,
        clientName: testClientName,
        onClose: onClose ?? () {},
      ),
    );
  }

  testWidgets('shows header title', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('アクセストークン発行'), findsOneWidget);
  });

  testWidgets('displays the token string', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text(testToken), findsOneWidget);
  });

  testWidgets('shows copy and share buttons', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('コピー'), findsOneWidget);
    expect(find.text('シェア'), findsOneWidget);
  });

  testWidgets('close button shows confirmation dialog', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('画面を閉じますか？'), findsOneWidget);
  });

  testWidgets('confirming close calls onClose', (tester) async {
    var closed = false;
    await tester.pumpWidget(buildSubject(onClose: () => closed = true));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
  });

  testWidgets('canceling close dialog dismisses it without calling onClose', (
    tester,
  ) async {
    var closed = false;
    await tester.pumpWidget(buildSubject(onClose: () => closed = true));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(closed, isFalse);
    expect(find.text('画面を閉じますか？'), findsNothing);
  });
}
