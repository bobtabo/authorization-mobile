// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/backends.dart';
import 'core/errors/app_exception.dart';
import 'core/result.dart';
import 'data/datasources/backend_local_data_source.dart';
import 'data/datasources/client_remote_data_source.dart';
import 'data/datasources/client_session_local_data_source.dart';
import 'data/datasources/deep_link_data_source.dart';
import 'data/repositories/backend_repository_impl.dart';
import 'data/repositories/client_repository_impl.dart';
import 'data/repositories/client_session_repository_impl.dart';
import 'demo/tap_indicator.dart';
import 'domain/entities/backend_option.dart';
import 'domain/entities/client_info.dart';
import 'domain/repositories/backend_repository.dart';
import 'domain/repositories/client_repository.dart';
import 'domain/repositories/client_session_repository.dart';
import 'domain/usecases/activate_client_usecase.dart';
import 'domain/usecases/fetch_client_info_usecase.dart';
import 'domain/usecases/load_saved_backend_usecase.dart';
import 'domain/usecases/parse_qr_usecase.dart';
import 'domain/usecases/restore_session_usecase.dart';
import 'domain/usecases/resume_client_usecase.dart';
import 'domain/usecases/select_backend_usecase.dart';
import 'domain/usecases/stop_client_usecase.dart';
import 'screens/activation_confirm_screen.dart';
import 'screens/home_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/token_display_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const ProviderScope(child: AuthorizationGatewayApp()));
}

/// アプリのルートウィジェット。テーマと [AppNavigator] を設定する。
class AuthorizationGatewayApp extends StatelessWidget {
  const AuthorizationGatewayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Authorization Gateway',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        useMaterial3: true,
      ),
      home: const DemoTapIndicatorOverlay(child: AppNavigator()),
    );
  }
}

/// アプリ内の画面遷移状態を表す列挙型。
enum AppScreen { splash, scanner, confirm, token, home }

/// アプリ全体の画面遷移とAPIコールを管理するルートウィジェット。
class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  AppScreen _currentScreen = AppScreen.splash;
  ClientInfo? _clientInfo;
  String _token = '';
  BackendOption _selectedBackend = kDefaultBackend;
  bool _isLoading = false;

  // TODO(#24): ViewModel化に伴い、これらの直接インスタンス化はRiverpod Providerの
  // ref.watch(...)に置き換える（Issue #23時点での一時的な繋ぎ）。
  final ClientRepository _clientRepository = ClientRepositoryImpl(
    ClientRemoteDataSource(),
  );
  final ClientSessionRepository _sessionRepository =
      ClientSessionRepositoryImpl(ClientSessionLocalDataSource());
  final BackendRepository _backendRepository = BackendRepositoryImpl(
    BackendLocalDataSource(),
  );
  final DeepLinkDataSource _deepLinkDataSource = DeepLinkDataSource();

  late final _fetchClientInfo = FetchClientInfoUseCase(_clientRepository);
  late final _activateClient = ActivateClientUseCase(_clientRepository);
  late final _stopClient = StopClientUseCase(_clientRepository);
  late final _resumeClient = ResumeClientUseCase(_clientRepository);
  late final _restoreSessionUseCase = RestoreSessionUseCase(
    _clientRepository,
    _sessionRepository,
  );
  late final _loadSavedBackendUseCase = LoadSavedBackendUseCase(
    _backendRepository,
  );
  late final _selectBackendUseCase = SelectBackendUseCase(_backendRepository);

  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _loadSavedBackend();
    _restoreSession();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedBackend() async {
    final backend = await _loadSavedBackendUseCase();
    setState(() => _selectedBackend = backend);
  }

  Future<void> _restoreSession() async {
    final clientInfo = await _restoreSessionUseCase();
    if (clientInfo == null) return;
    setState(() {
      _clientInfo = clientInfo;
      _currentScreen = AppScreen.home;
    });
  }

  Future<void> _handleSelectBackend(BackendOption backend) async {
    await _selectBackendUseCase(backend);
    setState(() => _selectedBackend = backend);
  }

  Future<void> _initDeepLinks() async {
    // アプリ起動時に受け取ったリンクを処理（アプリが終了していた場合）
    final initialUri = await _deepLinkDataSource.getInitialLink();
    if (initialUri != null) {
      await _handleDeepLink(initialUri);
    }

    // アプリ起動中に受け取ったリンクを処理
    _linkSub = _deepLinkDataSource.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    final parsed = const ParseQrUseCase()(uri);
    if (parsed == null) return;

    _setLoading(true);
    final result = await _fetchClientInfo(parsed.slug, parsed.identifier);
    switch (result) {
      case Ok(:final value):
        final alreadyStarted =
            value.status == ClientStatus.active ||
            value.status == ClientStatus.suspended;
        if (alreadyStarted) {
          await _sessionRepository.saveSession(parsed.slug, parsed.identifier);
        }
        setState(() {
          _clientInfo = value;
          _currentScreen = alreadyStarted ? AppScreen.home : AppScreen.confirm;
        });
      case Err(:final error):
        debugPrint('[fetchClientInfo] ${error.message}');
        await _showError(switch (error) {
          ApiFailure(:final statusCode) => 'クライアント情報の取得に失敗しました（$statusCode）',
          _ => '通信エラーが発生しました',
        });
    }
    _setLoading(false);
  }

  void _handleStartScan() {
    setState(() => _currentScreen = AppScreen.scanner);
  }

  void _handleQRScan(String qrData) {
    final uri = Uri.tryParse(qrData);
    if (uri != null && uri.hasScheme) {
      _handleDeepLink(uri);
    }
  }

  Future<void> _handleActivate() async {
    if (_clientInfo == null) return;
    _setLoading(true);
    final result = await _activateClient(
      _selectedBackend.slug,
      _clientInfo!.identifier,
    );
    switch (result) {
      case Ok(:final value):
        await _sessionRepository.saveSession(
          _selectedBackend.slug,
          _clientInfo!.identifier,
        );
        setState(() {
          _token = value;
          _clientInfo = _clientInfo?.copyWith(status: ClientStatus.active);
          _currentScreen = AppScreen.token;
        });
      case Err(:final error):
        debugPrint('[activateClient] ${error.message}');
        await _showError(switch (error) {
          ApiFailure(:final statusCode) => '利用開始に失敗しました（$statusCode）',
          _ => '通信エラーが発生しました',
        });
    }
    _setLoading(false);
  }

  void _handleCloseToken() {
    setState(() {
      _token = '';
      _currentScreen = AppScreen.home;
    });
  }

  Future<void> _handleSuspend() async {
    if (_clientInfo == null) return;
    _setLoading(true);
    final result = await _stopClient(
      _selectedBackend.slug,
      _clientInfo!.identifier,
    );
    switch (result) {
      case Ok():
        setState(() {
          _clientInfo = _clientInfo?.copyWith(status: ClientStatus.suspended);
        });
      case Err(:final error):
        debugPrint('[stopClient] ${error.message}');
        await _showError(switch (error) {
          ApiFailure(:final statusCode) => '利用停止に失敗しました（$statusCode）',
          _ => '通信エラーが発生しました',
        });
    }
    _setLoading(false);
  }

  Future<void> _handleResume() async {
    if (_clientInfo == null) return;
    _setLoading(true);
    final result = await _resumeClient(
      _selectedBackend.slug,
      _clientInfo!.identifier,
    );
    switch (result) {
      case Ok():
        setState(() {
          _clientInfo = _clientInfo?.copyWith(status: ClientStatus.active);
        });
      case Err(:final error):
        debugPrint('[resumeClient] ${error.message}');
        await _showError(switch (error) {
          ApiFailure(:final statusCode) => '利用開始に失敗しました（$statusCode）',
          _ => '通信エラーが発生しました',
        });
    }
    _setLoading(false);
  }

  void _handleBackToSplash() {
    setState(() => _currentScreen = AppScreen.splash);
  }

  void _handleBackToScanner() {
    setState(() => _currentScreen = AppScreen.scanner);
  }

  void _setLoading(bool v) => setState(() => _isLoading = v);

  Future<void> _showError(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = switch (_currentScreen) {
      AppScreen.splash => SplashScreen(
        onStart: _handleStartScan,
        selectedBackend: _selectedBackend,
        onSelectBackend: _handleSelectBackend,
      ),
      AppScreen.scanner => QRScannerScreen(
        onScan: _handleQRScan,
        onBack: _handleBackToSplash,
      ),
      AppScreen.confirm =>
        _clientInfo != null
            ? ActivationConfirmScreen(
                clientInfo: _clientInfo!,
                onActivate: () {
                  _handleActivate();
                },
                onBack: _handleBackToScanner,
              )
            : SplashScreen(
                onStart: _handleStartScan,
                selectedBackend: _selectedBackend,
                onSelectBackend: _handleSelectBackend,
              ),
      AppScreen.token =>
        _clientInfo != null
            ? TokenDisplayScreen(
                token: _token,
                clientName: _clientInfo!.name,
                onClose: _handleCloseToken,
              )
            : SplashScreen(
                onStart: _handleStartScan,
                selectedBackend: _selectedBackend,
                onSelectBackend: _handleSelectBackend,
              ),
      AppScreen.home =>
        _clientInfo != null
            ? HomeScreen(
                clientInfo: _clientInfo!,
                onSuspend: () {
                  _handleSuspend();
                },
                onResume: () {
                  _handleResume();
                },
                selectedBackend: _selectedBackend,
                onSelectBackend: _handleSelectBackend,
              )
            : SplashScreen(
                onStart: _handleStartScan,
                selectedBackend: _selectedBackend,
                onSelectBackend: _handleSelectBackend,
              ),
    };

    if (!_isLoading) return screen;
    return Stack(
      children: [
        screen,
        const ModalBarrier(dismissible: false, color: Colors.black45),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
