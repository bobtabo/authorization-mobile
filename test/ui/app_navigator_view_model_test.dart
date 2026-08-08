// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'dart:async';

import 'package:authorization_mobile/core/config/backends.dart';
import 'package:authorization_mobile/core/errors/app_exception.dart';
import 'package:authorization_mobile/core/result.dart';
import 'package:authorization_mobile/data/datasources/deep_link_data_source.dart';
import 'package:authorization_mobile/data/repositories/backend_repository_impl.dart';
import 'package:authorization_mobile/data/repositories/client_repository_impl.dart';
import 'package:authorization_mobile/data/repositories/client_session_repository_impl.dart';
import 'package:authorization_mobile/domain/entities/backend_option.dart';
import 'package:authorization_mobile/domain/entities/client_info.dart';
import 'package:authorization_mobile/domain/repositories/backend_repository.dart';
import 'package:authorization_mobile/domain/repositories/client_repository.dart';
import 'package:authorization_mobile/domain/repositories/client_session_repository.dart';
import 'package:authorization_mobile/ui/app_navigator/app_navigator_state.dart';
import 'package:authorization_mobile/ui/app_navigator/app_navigator_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeClientRepository implements ClientRepository {
  Result<ClientInfo>? fetchResult;
  Result<String>? activateResult;
  Result<void>? stopResult;
  Result<void>? resumeResult;

  @override
  Future<Result<ClientInfo>> fetchClientInfo(
    String slug,
    String identifier,
  ) async => fetchResult!;

  @override
  Future<Result<String>> activateClient(String slug, String identifier) async =>
      activateResult!;

  @override
  Future<Result<void>> stopClient(String slug, String identifier) async =>
      stopResult!;

  @override
  Future<Result<void>> resumeClient(String slug, String identifier) async =>
      resumeResult!;
}

class _FakeClientSessionRepository implements ClientSessionRepository {
  ({String slug, String identifier})? session;
  bool cleared = false;

  @override
  Future<({String slug, String identifier})?> loadSession() async => session;

  @override
  Future<void> saveSession(String slug, String identifier) async {
    session = (slug: slug, identifier: identifier);
  }

  @override
  Future<void> clearSession() async {
    cleared = true;
    session = null;
  }
}

class _FakeBackendRepository implements BackendRepository {
  _FakeBackendRepository({BackendOption? selected})
    : _selected = selected ?? kDefaultBackend;

  BackendOption _selected;

  @override
  Future<BackendOption> loadSelected() async => _selected;

  @override
  Future<void> saveSelected(BackendOption backend) async {
    _selected = backend;
  }
}

class _FakeDeepLinkDataSource extends DeepLinkDataSource {
  final _controller = StreamController<Uri>.broadcast();

  @override
  Future<Uri?> getInitialLink() async => null;

  @override
  Stream<Uri> get uriLinkStream => _controller.stream;
}

void main() {
  const clientInfo = ClientInfo(
    name: 'テスト株式会社',
    identifier: 'client_001',
    status: ClientStatus.preparing,
  );

  late _FakeClientRepository clientRepository;
  late _FakeClientSessionRepository sessionRepository;
  late _FakeBackendRepository backendRepository;
  late ProviderContainer container;

  ProviderContainer buildContainer() {
    clientRepository = _FakeClientRepository();
    sessionRepository = _FakeClientSessionRepository();
    backendRepository = _FakeBackendRepository();
    return ProviderContainer(
      overrides: [
        clientRepositoryProvider.overrideWithValue(clientRepository),
        clientSessionRepositoryProvider.overrideWithValue(sessionRepository),
        backendRepositoryProvider.overrideWithValue(backendRepository),
        deepLinkDataSourceProvider.overrideWithValue(_FakeDeepLinkDataSource()),
      ],
    );
  }

  tearDown(() => container.dispose());

  test('initial state is AppScreen.splash', () {
    container = buildContainer();
    final state = container.read(appNavigatorViewModelProvider);
    expect(state.currentScreen, AppScreen.splash);
    expect(state.selectedBackend, kDefaultBackend);
  });

  test(
    'handleDeepLink transitions to confirm when client is not started',
    () async {
      container = buildContainer();
      clientRepository.fetchResult = const Ok(clientInfo);
      final notifier = container.read(appNavigatorViewModelProvider.notifier);

      await notifier.handleDeepLink(
        Uri.parse('authgateway://clients/client_001/info'),
      );

      final state = container.read(appNavigatorViewModelProvider);
      expect(state.currentScreen, AppScreen.confirm);
      expect(state.clientInfo, clientInfo);
      expect(state.isLoading, isFalse);
    },
  );

  test(
    'handleDeepLink transitions to home when client is already active',
    () async {
      container = buildContainer();
      clientRepository.fetchResult = const Ok(
        ClientInfo(
          name: 'テスト株式会社',
          identifier: 'client_001',
          status: ClientStatus.active,
        ),
      );
      final notifier = container.read(appNavigatorViewModelProvider.notifier);

      await notifier.handleDeepLink(
        Uri.parse('authgateway://clients/client_001/info'),
      );

      final state = container.read(appNavigatorViewModelProvider);
      expect(state.currentScreen, AppScreen.home);
      expect(sessionRepository.session, (
        slug: 'php',
        identifier: 'client_001',
      ));
    },
  );

  test('handleDeepLink sets errorMessage when fetchClientInfo fails', () async {
    container = buildContainer();
    clientRepository.fetchResult = const Err(ApiFailure(500, 'server error'));
    final notifier = container.read(appNavigatorViewModelProvider.notifier);

    await notifier.handleDeepLink(
      Uri.parse('authgateway://clients/client_001/info'),
    );

    final state = container.read(appNavigatorViewModelProvider);
    expect(state.errorMessage, 'クライアント情報の取得に失敗しました（500）');
    expect(state.isLoading, isFalse);
  });

  test(
    'handleActivate success sets token, updates status, and moves to token screen',
    () async {
      container = buildContainer();
      clientRepository.fetchResult = const Ok(clientInfo);
      final notifier = container.read(appNavigatorViewModelProvider.notifier);
      await notifier.handleDeepLink(
        Uri.parse('authgateway://clients/client_001/info'),
      );
      clientRepository.activateResult = const Ok('access-token-xxx');

      await notifier.handleActivate();

      final state = container.read(appNavigatorViewModelProvider);
      expect(state.token, 'access-token-xxx');
      expect(state.currentScreen, AppScreen.token);
      expect(state.clientInfo?.status, ClientStatus.active);
      expect(sessionRepository.session, (
        slug: 'php',
        identifier: 'client_001',
      ));
    },
  );

  test(
    'handleActivate failure sets errorMessage and does not move screens',
    () async {
      container = buildContainer();
      clientRepository.fetchResult = const Ok(clientInfo);
      final notifier = container.read(appNavigatorViewModelProvider.notifier);
      await notifier.handleDeepLink(
        Uri.parse('authgateway://clients/client_001/info'),
      );
      clientRepository.activateResult = const Err(NetworkException());

      await notifier.handleActivate();

      final state = container.read(appNavigatorViewModelProvider);
      expect(state.errorMessage, '通信エラーが発生しました');
      expect(state.currentScreen, AppScreen.confirm);
    },
  );

  test('dismissError clears errorMessage', () async {
    container = buildContainer();
    clientRepository.fetchResult = const Err(NetworkException());
    final notifier = container.read(appNavigatorViewModelProvider.notifier);
    await notifier.handleDeepLink(
      Uri.parse('authgateway://clients/client_001/info'),
    );
    expect(
      container.read(appNavigatorViewModelProvider).errorMessage,
      isNotNull,
    );

    notifier.dismissError();

    expect(container.read(appNavigatorViewModelProvider).errorMessage, isNull);
  });

  test('handleStartScan moves to scanner screen', () {
    container = buildContainer();
    final notifier = container.read(appNavigatorViewModelProvider.notifier);

    notifier.handleStartScan();

    expect(
      container.read(appNavigatorViewModelProvider).currentScreen,
      AppScreen.scanner,
    );
  });

  test('handleBackToSplash and handleBackToScanner move screens back', () {
    container = buildContainer();
    final notifier = container.read(appNavigatorViewModelProvider.notifier);

    notifier.handleStartScan();
    notifier.handleBackToSplash();
    expect(
      container.read(appNavigatorViewModelProvider).currentScreen,
      AppScreen.splash,
    );

    notifier.handleStartScan();
    notifier.handleBackToScanner();
    expect(
      container.read(appNavigatorViewModelProvider).currentScreen,
      AppScreen.scanner,
    );
  });

  test('selectBackend persists and updates selectedBackend', () async {
    container = buildContainer();
    final notifier = container.read(appNavigatorViewModelProvider.notifier);
    const backend = BackendOption(name: 'Go (Gin)', slug: 'go-gin');

    await notifier.selectBackend(backend);

    expect(
      container.read(appNavigatorViewModelProvider).selectedBackend,
      backend,
    );
  });
}
