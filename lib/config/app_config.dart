import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'backends.dart';

/// アプリ全体の設定値とURL生成を管理するクラス。
class AppConfig {
  static String get _gatewayUrl =>
      dotenv.env['BASE_URL'] ?? 'http://localhost:8080';

  /// 指定スラッグのAPIベースURLを返す。
  static String apiBase(String slug) => '$_gatewayUrl/function/$slug/api';

  /// デフォルトバックエンドのAPIベースURLを返す。
  static String defaultApiBase() => apiBase(kDefaultBackend.slug);

  /// クライアント情報取得エンドポイントのURLを返す。
  static String clientInfoUrl(String slug, String identifier) =>
      '${apiBase(slug)}/clients/$identifier/info';

  /// 利用開始エンドポイントのURLを返す。
  static String clientStartUrl(String slug, String identifier) =>
      '${apiBase(slug)}/clients/$identifier/start';

  /// 利用停止エンドポイントのURLを返す。
  static String clientStopUrl(String slug, String identifier) =>
      '${apiBase(slug)}/clients/$identifier/stop';

  /// QRコードURIを解析してスラッグと識別子を返す。
  ///
  /// 形式: `authgateway://clients/{identifier}/info`
  /// 形式が一致しない場合は null を返す。
  static ({String slug, String identifier})? parseQrUri(Uri uri) {
    if (uri.scheme != 'authgateway' || uri.host != 'clients') return null;
    final match = RegExp(r'^/([^/]+)/info$').firstMatch(uri.path);
    if (match == null) return null;
    return (slug: kDefaultBackend.slug, identifier: match.group(1)!);
  }
}
