import 'package:authorization_mobile/core/config/backends.dart';
import 'package:authorization_mobile/data/datasources/backend_local_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BackendLocalDataSource', () {
    test('load returns default when nothing is saved', () async {
      final backend = await BackendLocalDataSource().load();
      expect(backend.slug, kDefaultBackend.slug);
    });

    test('save and load round-trips correctly', () async {
      final dataSource = BackendLocalDataSource();
      final goGin = kBackends.firstWhere((b) => b.slug == 'go-gin');
      await dataSource.save(goGin);
      final loaded = await dataSource.load();

      expect(loaded.slug, 'go-gin');
      expect(loaded.name, 'Go (Gin)');
    });

    test('load returns default for unknown saved slug', () async {
      SharedPreferences.setMockInitialValues({
        'selected_backend_slug': 'nonexistent',
      });
      final backend = await BackendLocalDataSource().load();
      expect(backend.slug, kDefaultBackend.slug);
    });

    test('save overwrites previous selection', () async {
      final dataSource = BackendLocalDataSource();
      final rust = kBackends.firstWhere((b) => b.slug == 'rust');
      final ts = kBackends.firstWhere((b) => b.slug == 'ts');
      await dataSource.save(rust);
      await dataSource.save(ts);
      final loaded = await dataSource.load();

      expect(loaded.slug, 'ts');
    });
  });
}
