import 'package:authorization_mobile/core/errors/app_exception.dart';
import 'package:authorization_mobile/core/result.dart';
import 'package:authorization_mobile/domain/entities/client_info.dart';
import 'package:authorization_mobile/domain/repositories/client_repository.dart';
import 'package:authorization_mobile/domain/usecases/activate_client_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeClientRepository implements ClientRepository {
  _FakeClientRepository({this.activateResult});

  Result<String>? activateResult;
  String? capturedSlug;
  String? capturedIdentifier;

  @override
  Future<Result<String>> activateClient(String slug, String identifier) async {
    capturedSlug = slug;
    capturedIdentifier = identifier;
    return activateResult!;
  }

  @override
  Future<Result<ClientInfo>> fetchClientInfo(String slug, String identifier) =>
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
    'delegates to ClientRepository.activateClient with the same arguments',
    () async {
      final repository = _FakeClientRepository(
        activateResult: const Ok('access-token'),
      );
      final useCase = ActivateClientUseCase(repository);

      final result = await useCase('php', 'client_001');

      expect(repository.capturedSlug, 'php');
      expect(repository.capturedIdentifier, 'client_001');
      expect(result, const Ok('access-token'));
    },
  );

  test('propagates Err results as-is', () async {
    const error = ApiFailure(500, 'server error');
    final repository = _FakeClientRepository(activateResult: const Err(error));
    final useCase = ActivateClientUseCase(repository);

    final result = await useCase('php', 'client_001');

    expect(result, const Err<String>(error));
  });
}
