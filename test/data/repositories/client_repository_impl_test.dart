import 'dart:convert';

import 'package:authorization_mobile/core/errors/app_exception.dart';
import 'package:authorization_mobile/core/result.dart';
import 'package:authorization_mobile/data/datasources/client_remote_data_source.dart';
import 'package:authorization_mobile/data/repositories/client_repository_impl.dart';
import 'package:authorization_mobile/domain/entities/client_info.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=http://localhost:8080\nAPI_ID=test');
  });

  ClientRepositoryImpl buildRepository(
    http.Response Function(http.Request request) handler,
  ) {
    return ClientRepositoryImpl(
      ClientRemoteDataSource(
        client: MockClient((request) async => handler(request)),
      ),
    );
  }

  test('fetchClientInfo returns Ok on success', () async {
    final repository = buildRepository(
      (request) => http.Response(
        jsonEncode({
          'name': 'テスト株式会社',
          'identifier': 'client_001',
          'status': 2,
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );

    final result = await repository.fetchClientInfo('php', 'client_001');

    expect(result, isA<Ok<ClientInfo>>());
    expect((result as Ok<ClientInfo>).value.status, ClientStatus.active);
  });

  test(
    'fetchClientInfo converts ApiException to Err(ApiFailure) preserving statusCode',
    () async {
      final repository = buildRepository(
        (request) => http.Response('not found', 404),
      );

      final result = await repository.fetchClientInfo('php', 'client_001');

      expect(result, isA<Err<ClientInfo>>());
      final error = (result as Err<ClientInfo>).error;
      expect(error, isA<ApiFailure>());
      expect((error as ApiFailure).statusCode, 404);
    },
  );

  test(
    'activateClient converts non-ApiException failures to Err(NetworkException)',
    () async {
      final repository = ClientRepositoryImpl(
        ClientRemoteDataSource(
          client: MockClient(
            (request) async => throw Exception('socket closed'),
          ),
        ),
      );

      final result = await repository.activateClient('php', 'client_001');

      expect(result, isA<Err<String>>());
      expect((result as Err<String>).error, isA<NetworkException>());
    },
  );

  test('stopClient returns Ok(null) on success', () async {
    final repository = buildRepository((request) => http.Response('', 200));

    final result = await repository.stopClient('php', 'client_001');

    expect(result, const Ok<void>(null));
  });

  test('resumeClient returns Ok(null) on success', () async {
    final repository = buildRepository((request) => http.Response('', 200));

    final result = await repository.resumeClient('php', 'client_001');

    expect(result, const Ok<void>(null));
  });
}
