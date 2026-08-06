import 'package:authorization_mobile/core/errors/app_exception.dart';
import 'package:authorization_mobile/core/result.dart';
import 'package:authorization_mobile/domain/entities/client_info.dart';
import 'package:authorization_mobile/domain/repositories/client_repository.dart';
import 'package:authorization_mobile/domain/usecases/stop_client_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeClientRepository implements ClientRepository {
  _FakeClientRepository({this.stopResult});

  Result<void>? stopResult;
  String? capturedSlug;
  String? capturedIdentifier;

  @override
  Future<Result<void>> stopClient(String slug, String identifier) async {
    capturedSlug = slug;
    capturedIdentifier = identifier;
    return stopResult!;
  }

  @override
  Future<Result<ClientInfo>> fetchClientInfo(String slug, String identifier) =>
      throw UnimplementedError();

  @override
  Future<Result<String>> activateClient(String slug, String identifier) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> resumeClient(String slug, String identifier) =>
      throw UnimplementedError();
}

void main() {
  test(
    'delegates to ClientRepository.stopClient with the same arguments',
    () async {
      final repository = _FakeClientRepository(stopResult: const Ok(null));
      final useCase = StopClientUseCase(repository);

      final result = await useCase('php', 'client_001');

      expect(repository.capturedSlug, 'php');
      expect(repository.capturedIdentifier, 'client_001');
      expect(result, const Ok<void>(null));
    },
  );

  test('propagates Err results as-is', () async {
    const error = NetworkException();
    final repository = _FakeClientRepository(stopResult: const Err(error));
    final useCase = StopClientUseCase(repository);

    final result = await useCase('php', 'client_001');

    expect(result, const Err<void>(error));
  });
}
