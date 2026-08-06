import 'package:authorization_mobile/core/config/app_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
