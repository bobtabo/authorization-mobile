import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'backends.dart';

class AppConfig {
  static String get _gatewayUrl =>
      dotenv.env['BASE_URL'] ?? 'http://localhost:8080';

  static String apiBase(String slug) => '$_gatewayUrl/function/$slug/api';

  static String defaultApiBase() => apiBase(kDefaultBackend.slug);

  static String clientInfoUrl(String slug, String identifier) =>
      '${apiBase(slug)}/clients/$identifier/info';

  static String clientStartUrl(String slug, String identifier) =>
      '${apiBase(slug)}/clients/$identifier/start';

  static String clientStopUrl(String slug, String identifier) =>
      '${apiBase(slug)}/clients/$identifier/stop';

  // QRコードURLからidentifierを抽出する
  // 形式: authgateway://clients/{identifier}/info
  static ({String slug, String identifier})? parseQrUri(Uri uri) {
    if (uri.scheme != 'authgateway' || uri.host != 'clients') return null;
    final match = RegExp(r'^/([^/]+)/info$').firstMatch(uri.path);
    if (match == null) return null;
    return (slug: kDefaultBackend.slug, identifier: match.group(1)!);
  }
}
