import 'package:authorization_mobile/core/config/backends.dart';
import 'package:authorization_mobile/data/datasources/backend_local_data_source.dart';
import 'package:authorization_mobile/data/repositories/backend_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BackendRepositoryImpl', () {
    test(
      'delegates to BackendLocalDataSource without wrapping in Result',
      () async {
        final repository = BackendRepositoryImpl(BackendLocalDataSource());

        expect((await repository.loadSelected()).slug, kDefaultBackend.slug);

        final target = kBackends.firstWhere((b) => b.slug == 'rust');
        await repository.saveSelected(target);

        expect((await repository.loadSelected()).slug, 'rust');
      },
    );
  });
}
