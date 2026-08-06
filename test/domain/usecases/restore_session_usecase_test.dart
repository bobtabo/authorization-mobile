import 'package:authorization_mobile/core/errors/app_exception.dart';
import 'package:authorization_mobile/core/result.dart';
import 'package:authorization_mobile/domain/entities/client_info.dart';
import 'package:authorization_mobile/domain/repositories/client_repository.dart';
import 'package:authorization_mobile/domain/repositories/client_session_repository.dart';
import 'package:authorization_mobile/domain/usecases/restore_session_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeClientRepository implements ClientRepository {
  _FakeClientRepository({this.fetchResult});

  Result<ClientInfo>? fetchResult;

  @override
  Future<Result<ClientInfo>> fetchClientInfo(
    String slug,
    String identifier,
  ) async => fetchResult!;

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

class _FakeClientSessionRepository implements ClientSessionRepository {
  _FakeClientSessionRepository({this.session});

  ({String slug, String identifier})? session;
  bool cleared = false;

  @override
  Future<({String slug, String identifier})?> loadSession() async => session;

  @override
  Future<void> saveSession(String slug, String identifier) =>
      throw UnimplementedError();

  @override
  Future<void> clearSession() async {
    cleared = true;
  }
}

void main() {
  const clientInfo = ClientInfo(
    name: 'テスト株式会社',
    identifier: 'client_001',
    status: ClientStatus.active,
  );

  test(
    'returns null without clearing the session when there is no saved session',
    () async {
      final clientRepository = _FakeClientRepository();
      final sessionRepository = _FakeClientSessionRepository();
      final useCase = RestoreSessionUseCase(
        clientRepository,
        sessionRepository,
      );

      final result = await useCase();

      expect(result, isNull);
      expect(sessionRepository.cleared, isFalse);
    },
  );

  test('returns the ClientInfo when status is active', () async {
    final clientRepository = _FakeClientRepository(
      fetchResult: const Ok(clientInfo),
    );
    final sessionRepository = _FakeClientSessionRepository(
      session: (slug: 'php', identifier: 'client_001'),
    );
    final useCase = RestoreSessionUseCase(clientRepository, sessionRepository);

    final result = await useCase();

    expect(result, clientInfo);
    expect(sessionRepository.cleared, isFalse);
  });

  test('returns the ClientInfo when status is suspended', () async {
    final clientRepository = _FakeClientRepository(
      fetchResult: const Ok(
        ClientInfo(
          name: 'テスト株式会社',
          identifier: 'client_001',
          status: ClientStatus.suspended,
        ),
      ),
    );
    final sessionRepository = _FakeClientSessionRepository(
      session: (slug: 'php', identifier: 'client_001'),
    );
    final useCase = RestoreSessionUseCase(clientRepository, sessionRepository);

    final result = await useCase();

    expect(result?.status, ClientStatus.suspended);
    expect(sessionRepository.cleared, isFalse);
  });

  test(
    'clears the session and returns null when status is preparing',
    () async {
      final clientRepository = _FakeClientRepository(
        fetchResult: const Ok(
          ClientInfo(
            name: 'テスト株式会社',
            identifier: 'client_001',
            status: ClientStatus.preparing,
          ),
        ),
      );
      final sessionRepository = _FakeClientSessionRepository(
        session: (slug: 'php', identifier: 'client_001'),
      );
      final useCase = RestoreSessionUseCase(
        clientRepository,
        sessionRepository,
      );

      final result = await useCase();

      expect(result, isNull);
      expect(sessionRepository.cleared, isTrue);
    },
  );

  test('returns null without clearing the session when fetch fails', () async {
    final clientRepository = _FakeClientRepository(
      fetchResult: const Err(NetworkException()),
    );
    final sessionRepository = _FakeClientSessionRepository(
      session: (slug: 'php', identifier: 'client_001'),
    );
    final useCase = RestoreSessionUseCase(clientRepository, sessionRepository);

    final result = await useCase();

    expect(result, isNull);
    expect(sessionRepository.cleared, isFalse);
  });
}
