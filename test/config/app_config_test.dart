import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:authorization_mobile/config/app_config.dart';

void main() {
  group('AppConfig.apiBase with API_ID set', () {
    setUpAll(() {
      dotenv.testLoad(
        fileInput: 'BASE_URL=https://example.ngrok-free.app\nAPI_ID=abc123def',
      );
    });

    test('builds URL with given slug and real API_ID', () {
      expect(
        AppConfig.apiBase('php'),
        'https://example.ngrok-free.app/restapis/abc123def/local/_user_request_/function/php/api',
      );
    });

    test('builds URL with hyphenated slug', () {
      expect(
        AppConfig.apiBase('go-gin'),
        'https://example.ngrok-free.app/restapis/abc123def/local/_user_request_/function/go-gin/api',
      );
    });

    test('defaultApiBase uses PHP slug', () {
      expect(
        AppConfig.defaultApiBase(),
        'https://example.ngrok-free.app/restapis/abc123def/local/_user_request_/function/php/api',
      );
    });
  });

  group('AppConfig.parseQrUri', () {
    test('parses valid authgateway URL', () {
      final uri = Uri.parse('authgateway://clients/client_test_001/info');
      final result = AppConfig.parseQrUri(uri);
      expect(result?.identifier, 'client_test_001');
    });

    test('returns null for wrong scheme', () {
      final uri = Uri.parse('https://example.com/clients/abc/info');
      expect(AppConfig.parseQrUri(uri), isNull);
    });

    test('returns null for wrong host', () {
      final uri = Uri.parse('authgateway://unknown/client_test_001/info');
      expect(AppConfig.parseQrUri(uri), isNull);
    });

    test('returns null for wrong path', () {
      final uri = Uri.parse('authgateway://clients/client_test_001/activate');
      expect(AppConfig.parseQrUri(uri), isNull);
    });
  });
}
