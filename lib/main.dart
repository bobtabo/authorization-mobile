import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'config/app_config.dart';
import 'config/backends.dart';
import 'models/client_info.dart';
import 'services/api_service.dart';
import 'services/backend_service.dart';
import 'services/client_session_service.dart';
import 'screens/splash_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/activation_confirm_screen.dart';
import 'screens/token_display_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const AuthorizationGatewayApp());
}

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
      home: const AppNavigator(),
    );
  }
}

enum AppScreen { splash, scanner, confirm, token, home }

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

  late final AppLinks _appLinks;
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
    final backend = await BackendService.load();
    setState(() => _selectedBackend = backend);
  }

  Future<void> _restoreSession() async {
    final session = await ClientSessionService.load();
    if (session == null) return;
    try {
      final clientInfo = await ApiService.fetchClientInfo(
        session.slug,
        session.identifier,
      );
      if (clientInfo.status == ClientStatus.active ||
          clientInfo.status == ClientStatus.suspended) {
        setState(() {
          _clientInfo = clientInfo;
          _currentScreen = AppScreen.home;
        });
      } else {
        await ClientSessionService.clear();
      }
    } catch (e, st) {
      debugPrint('[session restore] $e\n$st');
    }
  }

  Future<void> _handleSelectBackend(BackendOption backend) async {
    await BackendService.save(backend);
    setState(() => _selectedBackend = backend);
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // アプリ起動時に受け取ったリンクを処理（アプリが終了していた場合）
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      await _handleDeepLink(initialUri);
    }

    // アプリ起動中に受け取ったリンクを処理
    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    final parsed = AppConfig.parseQrUri(uri);
    if (parsed == null) return;

    _setLoading(true);
    try {
      final clientInfo = await ApiService.fetchClientInfo(
        parsed.slug,
        parsed.identifier,
      );
      final alreadyStarted = clientInfo.status == ClientStatus.active ||
          clientInfo.status == ClientStatus.suspended;
      if (alreadyStarted) {
        await ClientSessionService.save(parsed.slug, parsed.identifier);
      }
      setState(() {
        _clientInfo = clientInfo;
        _currentScreen =
            alreadyStarted ? AppScreen.home : AppScreen.confirm;
      });
    } on ApiException catch (e, st) {
      debugPrint('[fetchClientInfo] ${e.statusCode} ${e.message}\n$st');
      await _showError('クライアント情報の取得に失敗しました（${e.statusCode}）');
    } catch (e, st) {
      debugPrint('[fetchClientInfo] $e\n$st');
      await _showError('通信エラーが発生しました');
    } finally {
      _setLoading(false);
    }
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
    try {
      final token = await ApiService.activateClient(
        _selectedBackend.slug,
        _clientInfo!.identifier,
      );
      await ClientSessionService.save(
        _selectedBackend.slug,
        _clientInfo!.identifier,
      );
      setState(() {
        _token = token;
        _clientInfo = _clientInfo?.copyWith(status: ClientStatus.active);
        _currentScreen = AppScreen.token;
      });
    } on ApiException catch (e, st) {
      debugPrint('[activateClient] ${e.statusCode} ${e.message}\n$st');
      await _showError('利用開始に失敗しました（${e.statusCode}）');
    } catch (e, st) {
      debugPrint('[activateClient] $e\n$st');
      await _showError('通信エラーが発生しました');
    } finally {
      _setLoading(false);
    }
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
    try {
      await ApiService.stopClient(
        _selectedBackend.slug,
        _clientInfo!.identifier,
      );
      setState(() {
        _clientInfo = _clientInfo?.copyWith(status: ClientStatus.suspended);
      });
    } on ApiException catch (e, st) {
      debugPrint('[stopClient] ${e.statusCode} ${e.message}\n$st');
      await _showError('利用停止に失敗しました（${e.statusCode}）');
    } catch (e, st) {
      debugPrint('[stopClient] $e\n$st');
      await _showError('通信エラーが発生しました');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handleResume() async {
    if (_clientInfo == null) return;
    _setLoading(true);
    try {
      await ApiService.resumeClient(
        _selectedBackend.slug,
        _clientInfo!.identifier,
      );
      setState(() {
        _clientInfo = _clientInfo?.copyWith(status: ClientStatus.active);
      });
    } on ApiException catch (e, st) {
      debugPrint('[resumeClient] ${e.statusCode} ${e.message}\n$st');
      await _showError('利用開始に失敗しました（${e.statusCode}）');
    } catch (e, st) {
      debugPrint('[resumeClient] $e\n$st');
      await _showError('通信エラーが発生しました');
    } finally {
      _setLoading(false);
    }
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
