import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:authorization_mobile/config/backends.dart';
import 'package:authorization_mobile/models/client_info.dart';
import 'package:authorization_mobile/screens/home_screen.dart';

void main() {
  const activeClient = ClientInfo(
    name: '株式会社テスト',
    identifier: 'client_test_001',
    email: 'test@example.com',
    status: ClientStatus.active,
  );

  const suspendedClient = ClientInfo(
    name: '株式会社テスト',
    identifier: 'client_test_001',
    email: 'test@example.com',
    status: ClientStatus.suspended,
  );

  Widget buildSubject({
    required ClientInfo clientInfo,
    VoidCallback? onSuspend,
    VoidCallback? onResume,
  }) {
    return MaterialApp(
      home: HomeScreen(
        clientInfo: clientInfo,
        onSuspend: onSuspend ?? () {},
        onResume: onResume ?? () {},
        selectedBackend: kDefaultBackend,
        onSelectBackend: (_) async {},
      ),
    );
  }

  // HomeScreen has a repeat animation (_PulsingDot) so pumpAndSettle would
  // time out — use pump(Duration) instead.
  testWidgets('shows client name and identifier', (tester) async {
    await tester.pumpWidget(buildSubject(clientInfo: activeClient));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('株式会社テスト'), findsOneWidget);
    expect(find.text('client_test_001'), findsOneWidget);
  });

  testWidgets('shows 利用中 status when active', (tester) async {
    await tester.pumpWidget(buildSubject(clientInfo: activeClient));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('利用中'), findsOneWidget);
  });

  testWidgets('shows 停止中 status when suspended', (tester) async {
    await tester.pumpWidget(buildSubject(clientInfo: suspendedClient));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('停止中'), findsOneWidget);
  });

  testWidgets('shows 利用停止 button when active', (tester) async {
    await tester.pumpWidget(buildSubject(clientInfo: activeClient));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('利用停止'), findsOneWidget);
    expect(find.text('利用開始'), findsNothing);
  });

  testWidgets('shows 利用開始 button when suspended', (tester) async {
    await tester.pumpWidget(buildSubject(clientInfo: suspendedClient));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('利用開始'), findsOneWidget);
    expect(find.text('利用停止'), findsNothing);
  });

  testWidgets('suspend button shows confirmation dialog', (tester) async {
    await tester.pumpWidget(buildSubject(clientInfo: activeClient));
    await tester.pump(const Duration(seconds: 1));

    await tester.ensureVisible(find.text('利用停止'));
    await tester.tap(find.text('利用停止'));
    await tester.pump(); // trigger setState and build dialog
    await tester.pump(
      const Duration(milliseconds: 300),
    ); // run entry animations
    await tester
        .pump(); // drain zero-duration timers created during animation setup

    expect(find.text('利用停止しますか？'), findsOneWidget);
  });

  testWidgets('confirming suspend calls onSuspend', (tester) async {
    var suspended = false;
    await tester.pumpWidget(
      buildSubject(clientInfo: activeClient, onSuspend: () => suspended = true),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.ensureVisible(find.text('利用停止'));
    await tester.tap(find.text('利用停止'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.tap(find.text('停止する'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(suspended, isTrue);
  });

  testWidgets('canceling suspend dialog does not call onSuspend', (
    tester,
  ) async {
    var suspended = false;
    await tester.pumpWidget(
      buildSubject(clientInfo: activeClient, onSuspend: () => suspended = true),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.ensureVisible(find.text('利用停止'));
    await tester.tap(find.text('利用停止'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.tap(find.text('キャンセル'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(suspended, isFalse);
    expect(find.text('利用停止しますか？'), findsNothing);
  });

  testWidgets('resume button calls onResume', (tester) async {
    var resumed = false;
    await tester.pumpWidget(
      buildSubject(clientInfo: suspendedClient, onResume: () => resumed = true),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.ensureVisible(find.text('利用開始'));
    await tester.tap(find.text('利用開始'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(resumed, isTrue);
  });
}
