// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/config/backends.dart';
import '../../core/errors/app_exception.dart';
import '../../core/result.dart';
import '../../data/datasources/deep_link_data_source.dart';
import '../../data/repositories/backend_repository_impl.dart';
import '../../data/repositories/client_repository_impl.dart';
import '../../data/repositories/client_session_repository_impl.dart';
import '../../domain/entities/backend_option.dart';
import '../../domain/entities/client_info.dart';
import '../../domain/repositories/client_session_repository.dart';
import '../../domain/usecases/activate_client_usecase.dart';
import '../../domain/usecases/fetch_client_info_usecase.dart';
import '../../domain/usecases/load_saved_backend_usecase.dart';
import '../../domain/usecases/parse_qr_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';
import '../../domain/usecases/resume_client_usecase.dart';
import '../../domain/usecases/select_backend_usecase.dart';
import '../../domain/usecases/stop_client_usecase.dart';
import 'app_navigator_state.dart';

part 'app_navigator_view_model.g.dart';

/// アプリ全体の画面遷移とAPIコールを管理するViewModel。
///
/// 操作(Event) → UseCase呼び出し → 状態更新(State) → View再描画、という
/// 単一方向データフロー（UDF）を徹底する。エラーはstateの[AppNavigatorState.errorMessage]
/// にセットするのみで、このクラスからは直接ダイアログ等を表示しない。
@riverpod
class AppNavigatorViewModel extends _$AppNavigatorViewModel {
  late final ClientSessionRepository _sessionRepository;
  late final DeepLinkDataSource _deepLinkDataSource;

  late final FetchClientInfoUseCase _fetchClientInfo;
  late final ActivateClientUseCase _activateClient;
  late final StopClientUseCase _stopClient;
  late final ResumeClientUseCase _resumeClient;
  late final RestoreSessionUseCase _restoreSessionUseCase;
  late final LoadSavedBackendUseCase _loadSavedBackendUseCase;
  late final SelectBackendUseCase _selectBackendUseCase;

  StreamSubscription<Uri>? _linkSubscription;

  @override
  AppNavigatorState build() {
    final clientRepository = ref.watch(clientRepositoryProvider);
    _sessionRepository = ref.watch(clientSessionRepositoryProvider);
    final backendRepository = ref.watch(backendRepositoryProvider);
    _deepLinkDataSource = ref.watch(deepLinkDataSourceProvider);

    _fetchClientInfo = FetchClientInfoUseCase(clientRepository);
    _activateClient = ActivateClientUseCase(clientRepository);
    _stopClient = StopClientUseCase(clientRepository);
    _resumeClient = ResumeClientUseCase(clientRepository);
    _restoreSessionUseCase = RestoreSessionUseCase(
      clientRepository,
      _sessionRepository,
    );
    _loadSavedBackendUseCase = LoadSavedBackendUseCase(backendRepository);
    _selectBackendUseCase = SelectBackendUseCase(backendRepository);

    ref.onDispose(() => _linkSubscription?.cancel());

    _initDeepLinks();
    _loadSavedBackend();
    _restoreSession();

    return AppNavigatorState(selectedBackend: kDefaultBackend);
  }

  Future<void> _loadSavedBackend() async {
    final backend = await _loadSavedBackendUseCase();
    state = state.copyWith(selectedBackend: backend);
  }

  Future<void> _restoreSession() async {
    final clientInfo = await _restoreSessionUseCase();
    if (clientInfo == null) return;
    state = state.copyWith(
      clientInfo: clientInfo,
      currentScreen: AppScreen.home,
    );
  }

  Future<void> selectBackend(BackendOption backend) async {
    await _selectBackendUseCase(backend);
    state = state.copyWith(selectedBackend: backend);
  }

  Future<void> _initDeepLinks() async {
    // アプリ起動時に受け取ったリンクを処理（アプリが終了していた場合）
    final initialUri = await _deepLinkDataSource.getInitialLink();
    if (initialUri != null) {
      await handleDeepLink(initialUri);
    }

    // アプリ起動中に受け取ったリンクを処理
    _linkSubscription = _deepLinkDataSource.uriLinkStream.listen((uri) {
      handleDeepLink(uri);
    });
  }

  Future<void> handleDeepLink(Uri uri) async {
    final parsed = const ParseQrUseCase()(uri);
    if (parsed == null) return;

    state = state.copyWith(isLoading: true);
    final result = await _fetchClientInfo(parsed.slug, parsed.identifier);
    switch (result) {
      case Ok(:final value):
        final alreadyStarted =
            value.status == ClientStatus.active ||
            value.status == ClientStatus.suspended;
        if (alreadyStarted) {
          await _sessionRepository.saveSession(parsed.slug, parsed.identifier);
        }
        state = state.copyWith(
          clientInfo: value,
          currentScreen: alreadyStarted ? AppScreen.home : AppScreen.confirm,
        );
      case Err(:final error):
        state = state.copyWith(
          errorMessage: switch (error) {
            ApiFailure(:final statusCode) => 'クライアント情報の取得に失敗しました（$statusCode）',
            _ => '通信エラーが発生しました',
          },
        );
    }
    state = state.copyWith(isLoading: false);
  }

  void handleStartScan() {
    state = state.copyWith(currentScreen: AppScreen.scanner);
  }

  void handleQrScan(String qrData) {
    final uri = Uri.tryParse(qrData);
    if (uri != null && uri.hasScheme) {
      handleDeepLink(uri);
    }
  }

  Future<void> handleActivate() async {
    final clientInfo = state.clientInfo;
    if (clientInfo == null) return;
    state = state.copyWith(isLoading: true);
    final result = await _activateClient(
      state.selectedBackend.slug,
      clientInfo.identifier,
    );
    switch (result) {
      case Ok(:final value):
        await _sessionRepository.saveSession(
          state.selectedBackend.slug,
          clientInfo.identifier,
        );
        state = state.copyWith(
          token: value,
          clientInfo: clientInfo.copyWith(status: ClientStatus.active),
          currentScreen: AppScreen.token,
        );
      case Err(:final error):
        state = state.copyWith(
          errorMessage: switch (error) {
            ApiFailure(:final statusCode) => '利用開始に失敗しました（$statusCode）',
            _ => '通信エラーが発生しました',
          },
        );
    }
    state = state.copyWith(isLoading: false);
  }

  void handleCloseToken() {
    state = state.copyWith(token: '', currentScreen: AppScreen.home);
  }

  Future<void> handleSuspend() async {
    final clientInfo = state.clientInfo;
    if (clientInfo == null) return;
    state = state.copyWith(isLoading: true);
    final result = await _stopClient(
      state.selectedBackend.slug,
      clientInfo.identifier,
    );
    switch (result) {
      case Ok():
        state = state.copyWith(
          clientInfo: clientInfo.copyWith(status: ClientStatus.suspended),
        );
      case Err(:final error):
        state = state.copyWith(
          errorMessage: switch (error) {
            ApiFailure(:final statusCode) => '利用停止に失敗しました（$statusCode）',
            _ => '通信エラーが発生しました',
          },
        );
    }
    state = state.copyWith(isLoading: false);
  }

  Future<void> handleResume() async {
    final clientInfo = state.clientInfo;
    if (clientInfo == null) return;
    state = state.copyWith(isLoading: true);
    final result = await _resumeClient(
      state.selectedBackend.slug,
      clientInfo.identifier,
    );
    switch (result) {
      case Ok():
        state = state.copyWith(
          clientInfo: clientInfo.copyWith(status: ClientStatus.active),
        );
      case Err(:final error):
        state = state.copyWith(
          errorMessage: switch (error) {
            ApiFailure(:final statusCode) => '利用開始に失敗しました（$statusCode）',
            _ => '通信エラーが発生しました',
          },
        );
    }
    state = state.copyWith(isLoading: false);
  }

  void handleBackToSplash() {
    state = state.copyWith(currentScreen: AppScreen.splash);
  }

  void handleBackToScanner() {
    state = state.copyWith(currentScreen: AppScreen.scanner);
  }

  /// エラーダイアログを閉じた後に呼び、[AppNavigatorState.errorMessage] を
  /// クリアする。同じ文言のエラーが再発した際にも `ref.listen` で検知できる
  /// ようにするため（`errorMessage` が非nullのままだと状態が変化しない）。
  void dismissError() {
    state = state.copyWith(errorMessage: null);
  }
}
