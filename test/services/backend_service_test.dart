import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:authorization_mobile/config/backends.dart';
import 'package:authorization_mobile/services/backend_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BackendService', () {
    test('load returns default when nothing is saved', () async {
      final backend = await BackendService.load();
      expect(backend.slug, kDefaultBackend.slug);
    });

    test('save and load round-trips correctly', () async {
      final goGin = kBackends.firstWhere((b) => b.slug == 'go-gin');
      await BackendService.save(goGin);
      final loaded = await BackendService.load();

      expect(loaded.slug, 'go-gin');
      expect(loaded.name, 'Go (Gin)');
    });

    test('load returns default for unknown saved slug', () async {
      SharedPreferences.setMockInitialValues({
        'selected_backend_slug': 'nonexistent',
      });
      final backend = await BackendService.load();
      expect(backend.slug, kDefaultBackend.slug);
    });

    test('save overwrites previous selection', () async {
      final rust = kBackends.firstWhere((b) => b.slug == 'rust');
      final ts = kBackends.firstWhere((b) => b.slug == 'ts');
      await BackendService.save(rust);
      await BackendService.save(ts);
      final loaded = await BackendService.load();

      expect(loaded.slug, 'ts');
    });
  });
}
