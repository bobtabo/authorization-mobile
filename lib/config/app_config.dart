import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'backends.dart';

class AppConfig {
  static String get _gatewayUrl =>
      dotenv.env['BASE_URL'] ?? 'http://localhost:8080';

  static String apiBase(String slug) => '$_gatewayUrl/function/$slug/api';

  static String defaultApiBase() => apiBase(kDefaultBackend.slug);

  // ディープリンクのパス定義
  // TODO: バックエンドのURL設計確定後に更新する
  static const String activatePath = '/activate';

  // Universal Links / App Links で使用するホスト
  static String get deepLinkHost => Uri.parse(_gatewayUrl).host;
}
