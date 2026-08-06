import 'package:authorization_mobile/data/datasources/client_session_local_data_source.dart';
import 'package:authorization_mobile/data/repositories/client_session_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ClientSessionRepositoryImpl', () {
    test(
      'delegates to ClientSessionLocalDataSource without wrapping in Result',
      () async {
        final repository = ClientSessionRepositoryImpl(
          ClientSessionLocalDataSource(),
        );

        expect(await repository.loadSession(), isNull);

        await repository.saveSession('php', 'client_001');
        final session = await repository.loadSession();
        expect(session?.slug, 'php');
        expect(session?.identifier, 'client_001');

        await repository.clearSession();
        expect(await repository.loadSession(), isNull);
      },
    );
  });
}
