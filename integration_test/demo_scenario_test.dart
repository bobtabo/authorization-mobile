// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

// デモ操作を自動再生する integration_test。
//
// QRスキャン → クライアント情報確認 → 利用開始 → アクセストークン表示 →
// ホーム画面でステータス（利用中）確認、までを1本のシナリオとして自動実行する。
// 各操作の間にウェイトを入れ、画面遷移アニメーションが録画で見やすくなるように
// している。
//
// 重要な方針:
//   - 実サーバー（LocalStack / ngrok / 実バックエンド）には一切接続しない。
//     すべてのAPI応答は `MockClient` でモックする。
//   - シナリオは「ステータス確認」で終わり、利用停止は行わない。
//
// 実行例（録画で見える形。ヘッドレス不可）:
//   flutter test integration_test/demo_scenario_test.dart -d <device-id>
//   もしくは統合スクリプト: bash scripts/record-demo-auto.sh <ios|android>

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';

import 'package:authorization_mobile/main.dart';
import 'package:authorization_mobile/services/api_service.dart';

/// デモ用モックデータ（バックエンド側デモの表示名・メールアドレスと揃える）。
const _clientName = '株式会社デモテスト';
const _clientEmail = 'demo@example.com';
const _identifier = 'client_test_001';
const _demoToken = 'demo-access-token-xxxxxxxx';

/// ClientStatus: Pending=0, Inactive=1, Active=2, Suspended=3, Closed=4
const _statusPreparing = 0;

/// 録画時（`--dart-define=DEMO_SCAN_PREVIEW=true`）はスキャナー画面がサンプルQRを
/// 表示し、自動的にスキャンが成立する。この場合はテストスキャン操作を行わない。
const _demoScanPreview = bool.fromEnvironment('DEMO_SCAN_PREVIEW');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // 実サーバーに繋がず、URL生成の assert（API_ID 未設定）を通すためのダミー設定。
    dotenv.testLoad(fileInput: 'BASE_URL=http://localhost:8080\nAPI_ID=demo');

    // API応答はすべてモック。fetchClientInfo と activateClient の2つで足りる。
    ApiService.client = MockClient((request) async {
      final path = request.url.path;
      final headers = {'content-type': 'application/json'};
      if (path.endsWith('/info')) {
        return http.Response(
          jsonEncode({
            'name': _clientName,
            'identifier': _identifier,
            'email': _clientEmail,
            'status': _statusPreparing,
          }),
          200,
          headers: headers,
        );
      }
      if (path.endsWith('/start')) {
        return http.Response(
          jsonEncode({'access_token': _demoToken}),
          200,
          headers: headers,
        );
      }
      return http.Response('unexpected request: $path', 404);
    });
  });

  tearDown(() {
    ApiService.client = http.Client();
  });

  testWidgets('デモシナリオ: QRスキャン〜ステータス確認（利用停止はしない）', (tester) async {
    await tester.pumpWidget(const AuthorizationGatewayApp());
    await _hold(tester);

    // 1. スプラッシュ画面: 「QRコードをスキャン」
    expect(find.text('QRコードをスキャン'), findsOneWidget);
    await tester.tap(find.text('QRコードをスキャン'));
    await _hold(tester);

    // 2. QRスキャナー画面
    if (_demoScanPreview) {
      // 録画モード: サンプルQRコードのプレビューが表示され、少し待つと自動的に
      // スキャンが成立して次の画面へ遷移する。テストスキャン操作は行わない。
      await _hold(tester, ms: 3000);
    } else {
      // 通常モード（カメラの無い環境など）: 「テストスキャン」ボタンをタップして
      // 値を入力し、擬似的にスキャンを成立させる。
      //    - iOS Simulator など カメラが無い環境: errorBuilder が
      //      _SimulatorFallback を表示し、その中のボタンが先頭になる。
      //    - カメラが使えるエミュレーター: kDebugMode のオーバーレイボタンが表示
      //      される。integration_test 実行中はカメラプレビューが初期化されない
      //      ことがあるが、ボタン側で stop()/start() の例外を握りつぶしているため
      //      問題なくダイアログを開ける。
      //    どちらの環境でも widget ツリー先頭の「テストスキャン」を選べばよい。
      await _hold(tester);
      await tester.tap(find.text('テストスキャン').first);
      await _hold(tester);

      // 3. テストスキャンダイアログ: 値は編集不要のまま「スキャン」
      await tester.tap(find.widgetWithText(FilledButton, 'スキャン'));
      await _hold(tester);
    }

    // 4. クライアント情報確認画面: 情報を確認して「利用開始する」
    expect(find.text(_clientName), findsWidgets);
    expect(find.text(_clientEmail), findsWidgets);
    await tester.tap(find.widgetWithText(ElevatedButton, '利用開始する'));
    await _hold(tester);

    // 5. アクセストークン表示画面: トークンを確認して閉じる
    expect(find.text(_demoToken), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'この画面を閉じる'));
    await _hold(tester);

    // 5-1. 閉じる確認ダイアログ（2段階）: 「閉じる」
    await tester.tap(find.widgetWithText(ElevatedButton, '閉じる'));
    await _hold(tester);

    // 6. ホーム画面: ステータス「利用中」を確認して終了（利用停止はしない）
    expect(find.text('利用中'), findsWidgets);
    await _hold(tester, ms: 2500);
  });
}

/// 一定時間フレームを描画し続けて、遷移アニメーションを進めつつ
/// 録画で見やすいウェイトを入れるヘルパー。
///
/// 画面に繰り返しアニメーション（スプラッシュのフロート等）があるため
/// `pumpAndSettle` は使えない。固定回数の `pump` で代替する。
Future<void> _hold(WidgetTester tester, {int ms = 1500}) async {
  final deadline = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}
