import 'package:authorization_mobile/data/datasources/platform_actions_data_source.dart';
import 'package:authorization_mobile/ui/token_display/view/token_display_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePlatformActionsDataSource extends PlatformActionsDataSource {
  bool copyCalled = false;
  String? copiedText;

  @override
  Future<void> copyToClipboard(String text) async {
    copyCalled = true;
    copiedText = text;
  }
}

void main() {
  const testToken = 'sk_live_test_token_abc123';
  const testClientName = '株式会社テスト';

  late _FakePlatformActionsDataSource fakePlatformActions;

  // riverpod_lint の scoped_providers_should_specify_dependencies は
  // 「pumpWidget に直接渡された ProviderScope」だけを静的に無害と認識するため、
  // Widgetを返すヘルパーではなく pumpWidget 自体を行う関数にしている。
  Future<void> pumpTokenDisplay(WidgetTester tester, {VoidCallback? onClose}) {
    fakePlatformActions = _FakePlatformActionsDataSource();
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformActionsDataSourceProvider.overrideWithValue(
            fakePlatformActions,
          ),
        ],
        child: MaterialApp(
          home: TokenDisplayScreen(
            token: testToken,
            clientName: testClientName,
            onClose: onClose ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows header title', (tester) async {
    await pumpTokenDisplay(tester);
    await tester.pumpAndSettle();

    expect(find.text('アクセストークン発行'), findsOneWidget);
  });

  testWidgets('displays the token string', (tester) async {
    await pumpTokenDisplay(tester);
    await tester.pumpAndSettle();

    expect(find.text(testToken), findsOneWidget);
  });

  testWidgets('shows copy and share buttons', (tester) async {
    await pumpTokenDisplay(tester);
    await tester.pumpAndSettle();

    expect(find.text('コピー'), findsOneWidget);
    expect(find.text('シェア'), findsOneWidget);
  });

  testWidgets('tapping copy calls PlatformActionsDataSource.copyToClipboard', (
    tester,
  ) async {
    await pumpTokenDisplay(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'コピー'));
    await tester.pump();

    expect(fakePlatformActions.copyCalled, isTrue);
    expect(fakePlatformActions.copiedText, testToken);
    expect(find.text('コピー済み'), findsOneWidget);

    // _handleCopy 内の2秒後リセット用Timerを消化してから終了する
    // （残したままテストを終えると pending timer でテストが失敗する）。
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('close button shows confirmation dialog', (tester) async {
    await pumpTokenDisplay(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('画面を閉じますか？'), findsOneWidget);
  });

  testWidgets('confirming close calls onClose', (tester) async {
    var closed = false;
    await pumpTokenDisplay(tester, onClose: () => closed = true);
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
    await pumpTokenDisplay(tester, onClose: () => closed = true);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(closed, isFalse);
    expect(find.text('画面を閉じますか？'), findsNothing);
  });
}
