import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:authorization_mobile/config/app_config.dart';

void main() {
  setUpAll(() {
    // Initialize dotenv with no values → BASE_URL is absent → falls back to 'http://localhost:8080'
    dotenv.testLoad();
  });
  group('AppConfig.apiBase', () {
    test('builds URL with given slug', () {
      expect(
        AppConfig.apiBase('php'),
        'http://localhost:8080/function/php/api',
      );
    });

    test('builds URL with hyphenated slug', () {
      expect(
        AppConfig.apiBase('go-gin'),
        'http://localhost:8080/function/go-gin/api',
      );
    });
  });

  group('AppConfig.defaultApiBase', () {
    test('uses PHP slug', () {
      expect(
        AppConfig.defaultApiBase(),
        'http://localhost:8080/function/php/api',
      );
    });
  });

  group('AppConfig.deepLinkHost', () {
    test('returns localhost from fallback BASE_URL', () {
      expect(AppConfig.deepLinkHost, 'localhost');
    });
  });
}
