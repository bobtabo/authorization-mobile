import 'dart:async';
import 'dart:convert';

import 'package:authorization_mobile/data/datasources/client_remote_data_source.dart';
import 'package:authorization_mobile/domain/entities/client_info.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=http://localhost:8080\nAPI_ID=test');
  });

  ClientRemoteDataSource buildDataSource(
    http.Response Function(http.Request request) handler,
  ) {
    return ClientRemoteDataSource(
      client: MockClient((request) async => handler(request)),
    );
  }

  /// レスポンスが (タイムアウト時間より長く) 帰ってこないバックエンドを模倣する。
  ClientRemoteDataSource buildHangingDataSource() {
    return ClientRemoteDataSource(
      client: MockClient((request) async {
        await Future<void>.delayed(const Duration(seconds: 30));
        return http.Response('', 200);
      }),
    );
  }

  // レスポンスボディに日本語を含めるため、charsetを明示する
  // （httpパッケージはcontent-typeにcharset指定が無いとLatin1で
  // エンコードしようとし、非ASCII文字でエラーになる）。
  http.Response jsonResponse(Map<String, Object?> body) => http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  group('fetchClientInfo', () {
    test('parses a successful response', () async {
      final dataSource = buildDataSource((request) {
        expect(request.url.path, endsWith('/clients/client_001/info'));
        return jsonResponse({
          'name': 'テスト株式会社',
          'identifier': 'client_001',
          'email': 'test@example.com',
          'status': 2,
        });
      });

      final result = await dataSource.fetchClientInfo('php', 'client_001');

      expect(
        result,
        const ClientInfo(
          name: 'テスト株式会社',
          identifier: 'client_001',
          email: 'test@example.com',
          status: ClientStatus.active,
        ),
      );
    });

    test('defaults status to preparing for unmapped values', () async {
      final dataSource = buildDataSource(
        (request) => jsonResponse({
          'name': 'テスト株式会社',
          'identifier': 'client_001',
          'status': 0,
        }),
      );

      final result = await dataSource.fetchClientInfo('php', 'client_001');

      expect(result.status, ClientStatus.preparing);
      expect(result.email, '');
    });

    test('throws ApiException with statusCode on non-200 response', () async {
      final dataSource = buildDataSource(
        (request) => http.Response('not found', 404),
      );

      await expectLater(
        () => dataSource.fetchClientInfo('php', 'client_001'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('throws TimeoutException when the backend never responds', () {
      fakeAsync((async) {
        final dataSource = buildHangingDataSource();
        Object? error;
        dataSource.fetchClientInfo('php', 'client_001').catchError((e) {
          error = e;
          return const ClientInfo(
            name: '',
            identifier: '',
            status: ClientStatus.preparing,
          );
        });

        async.elapse(const Duration(seconds: 16));

        expect(error, isA<TimeoutException>());
      });
    });
  });

  group('activateClient', () {
    test('returns the access token', () async {
      final dataSource = buildDataSource((request) {
        expect(request.url.path, endsWith('/clients/client_001/start'));
        return jsonResponse({'access_token': 'token-abc'});
      });

      final token = await dataSource.activateClient('php', 'client_001');

      expect(token, 'token-abc');
    });

    test('throws ApiException on non-200 response', () async {
      final dataSource = buildDataSource(
        (request) => http.Response('server error', 500),
      );

      await expectLater(
        () => dataSource.activateClient('php', 'client_001'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('throws TimeoutException when the backend never responds', () {
      fakeAsync((async) {
        final dataSource = buildHangingDataSource();
        Object? error;
        dataSource.activateClient('php', 'client_001').catchError((e) {
          error = e;
          return '';
        });

        async.elapse(const Duration(seconds: 16));

        expect(error, isA<TimeoutException>());
      });
    });
  });

  group('stopClient', () {
    test('completes normally on 200 response', () async {
      final dataSource = buildDataSource((request) {
        expect(request.url.path, endsWith('/clients/client_001/stop'));
        return http.Response('', 200);
      });

      await expectLater(dataSource.stopClient('php', 'client_001'), completes);
    });

    test('throws ApiException on non-200 response', () async {
      final dataSource = buildDataSource(
        (request) => http.Response('forbidden', 403),
      );

      await expectLater(
        () => dataSource.stopClient('php', 'client_001'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });

    test('throws TimeoutException when the backend never responds', () {
      fakeAsync((async) {
        final dataSource = buildHangingDataSource();
        Object? error;
        dataSource.stopClient('php', 'client_001').catchError((e) {
          error = e;
        });

        async.elapse(const Duration(seconds: 16));

        expect(error, isA<TimeoutException>());
      });
    });
  });

  group('resumeClient', () {
    test('completes normally on 200 response', () async {
      final dataSource = buildDataSource((request) {
        expect(request.url.path, endsWith('/clients/client_001/start'));
        return http.Response('', 200);
      });

      await expectLater(
        dataSource.resumeClient('php', 'client_001'),
        completes,
      );
    });

    test('throws ApiException on non-200 response', () async {
      final dataSource = buildDataSource(
        (request) => http.Response('server error', 500),
      );

      await expectLater(
        () => dataSource.resumeClient('php', 'client_001'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('throws TimeoutException when the backend never responds', () {
      fakeAsync((async) {
        final dataSource = buildHangingDataSource();
        Object? error;
        dataSource.resumeClient('php', 'client_001').catchError((e) {
          error = e;
        });

        async.elapse(const Duration(seconds: 16));

        expect(error, isA<TimeoutException>());
      });
    });
  });
}
