import 'package:authorization_mobile/core/errors/app_exception.dart';
import 'package:authorization_mobile/core/result.dart';
import 'package:authorization_mobile/domain/entities/client_info.dart';
import 'package:authorization_mobile/domain/repositories/client_repository.dart';
import 'package:authorization_mobile/domain/usecases/fetch_client_info_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeClientRepository implements ClientRepository {
  _FakeClientRepository({this.fetchResult});

  Result<ClientInfo>? fetchResult;
  String? capturedSlug;
  String? capturedIdentifier;

  @override
  Future<Result<ClientInfo>> fetchClientInfo(
    String slug,
    String identifier,
  ) async {
    capturedSlug = slug;
    capturedIdentifier = identifier;
    return fetchResult!;
  }

  @override
  Future<Result<String>> activateClient(String slug, String identifier) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> stopClient(String slug, String identifier) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> resumeClient(String slug, String identifier) =>
      throw UnimplementedError();
}

void main() {
  test(
    'delegates to ClientRepository.fetchClientInfo with the same arguments',
    () async {
      const clientInfo = ClientInfo(
        name: 'テスト株式会社',
        identifier: 'client_001',
        status: ClientStatus.active,
      );
      final repository = _FakeClientRepository(
        fetchResult: const Ok(clientInfo),
      );
      final useCase = FetchClientInfoUseCase(repository);

      final result = await useCase('php', 'client_001');

      expect(repository.capturedSlug, 'php');
      expect(repository.capturedIdentifier, 'client_001');
      expect(result, const Ok(clientInfo));
    },
  );

  test('propagates Err results as-is', () async {
    const error = ApiFailure(404, 'not found');
    final repository = _FakeClientRepository(fetchResult: const Err(error));
    final useCase = FetchClientInfoUseCase(repository);

    final result = await useCase('php', 'client_001');

    expect(result, const Err<ClientInfo>(error));
  });
}
