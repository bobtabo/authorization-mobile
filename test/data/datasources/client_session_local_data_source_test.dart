import 'package:authorization_mobile/data/datasources/client_session_local_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ClientSessionLocalDataSource', () {
    test('load returns null when nothing is saved', () async {
      final session = await ClientSessionLocalDataSource().load();
      expect(session, isNull);
    });

    test('save and load round-trips correctly', () async {
      final dataSource = ClientSessionLocalDataSource();
      await dataSource.save('php', 'client_001');

      final session = await dataSource.load();

      expect(session?.slug, 'php');
      expect(session?.identifier, 'client_001');
    });

    test('clear removes the saved session', () async {
      final dataSource = ClientSessionLocalDataSource();
      await dataSource.save('php', 'client_001');
      await dataSource.clear();

      final session = await dataSource.load();

      expect(session, isNull);
    });
  });
}
