import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'https://apis.authorization-php.dev';

  // ディープリンクのパス定義
  // TODO: バックエンドのURL設計確定後に更新する
  static const String activatePath = '/activate';

  // Universal Links / App Links で使用するホスト
  static String get deepLinkHost => Uri.parse(baseUrl).host;
}
