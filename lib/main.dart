import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'config/app_config.dart';
import 'config/backends.dart';
import 'models/client_info.dart';
import 'services/backend_service.dart';
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
        ),
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

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _loadSavedBackend();
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

  Future<void> _handleSelectBackend(BackendOption backend) async {
    await BackendService.save(backend);
    setState(() => _selectedBackend = backend);
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // アプリ起動時に受け取ったリンクを処理（アプリが終了していた場合）
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // アプリ起動中に受け取ったリンクを処理
    _linkSub = _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri uri) {
    // TODO: バックエンドのURL設計確定後にパス・パラメーター名を更新する
    if (uri.path != AppConfig.activatePath) return;

    final clientId = uri.queryParameters['client_id'];
    if (clientId == null || clientId.isEmpty) return;

    // TODO: clientId を使ってバックエンドからクライアント情報を取得する
    // ディープリンク直接起動はデフォルト（PHP）で通信
    final clientInfo = ClientInfo(
      name: '株式会社モックデータ商事',
      identifier: clientId,
      email: 'example@gmail.com',
      status: ClientStatus.preparing,
    );

    setState(() {
      _clientInfo = clientInfo;
      _currentScreen = AppScreen.confirm;
    });
  }

  void _handleStartScan() {
    setState(() => _currentScreen = AppScreen.scanner);
  }

  void _handleQRScan(String qrData) {
    final uri = Uri.tryParse(qrData);
    if (uri != null && uri.hasScheme) {
      _handleDeepLink(uri);
      return;
    }

    const mockClientInfo = ClientInfo(
      name: '株式会社モックデータ商事',
      identifier: 'client_2026051_sample_corp',
      email: 'example@gmail.com',
      status: ClientStatus.preparing,
    );
    setState(() {
      _clientInfo = mockClientInfo;
      _currentScreen = AppScreen.confirm;
    });
  }

  void _handleActivate() {
    const mockToken =
        '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';
    setState(() {
      _token = mockToken;
      _clientInfo = _clientInfo?.copyWith(status: ClientStatus.active);
      _currentScreen = AppScreen.token;
    });
  }

  void _handleCloseToken() {
    setState(() {
      _token = '';
      _currentScreen = AppScreen.home;
    });
  }

  void _handleSuspend() {
    setState(() {
      _clientInfo = _clientInfo?.copyWith(status: ClientStatus.suspended);
    });
  }

  void _handleResume() {
    setState(() {
      _clientInfo = _clientInfo?.copyWith(status: ClientStatus.active);
    });
  }

  void _handleBackToSplash() {
    setState(() => _currentScreen = AppScreen.splash);
  }

  void _handleBackToScanner() {
    setState(() => _currentScreen = AppScreen.scanner);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_currentScreen) {
      AppScreen.splash => SplashScreen(
          onStart: _handleStartScan,
          selectedBackend: _selectedBackend,
          onSelectBackend: _handleSelectBackend,
        ),
      AppScreen.scanner => QRScannerScreen(
          onScan: _handleQRScan,
          onBack: _handleBackToSplash,
        ),
      AppScreen.confirm => _clientInfo != null
          ? ActivationConfirmScreen(
              clientInfo: _clientInfo!,
              onActivate: _handleActivate,
              onBack: _handleBackToScanner,
            )
          : SplashScreen(
              onStart: _handleStartScan,
              selectedBackend: _selectedBackend,
              onSelectBackend: _handleSelectBackend,
            ),
      AppScreen.token => _clientInfo != null
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
      AppScreen.home => _clientInfo != null
          ? HomeScreen(
              clientInfo: _clientInfo!,
              onSuspend: _handleSuspend,
              onResume: _handleResume,
              selectedBackend: _selectedBackend,
              onSelectBackend: _handleSelectBackend,
            )
          : SplashScreen(
              onStart: _handleStartScan,
              selectedBackend: _selectedBackend,
              onSelectBackend: _handleSelectBackend,
            ),
    };
  }
}
