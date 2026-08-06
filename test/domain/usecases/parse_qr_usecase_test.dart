import 'package:authorization_mobile/domain/usecases/parse_qr_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = ParseQrUseCase();

  group('ParseQrUseCase', () {
    test('parses valid authgateway URL', () {
      final uri = Uri.parse('authgateway://clients/client_test_001/info');
      final result = useCase(uri);
      expect(result?.identifier, 'client_test_001');
    });

    test('returns null for wrong scheme', () {
      final uri = Uri.parse('https://example.com/clients/abc/info');
      expect(useCase(uri), isNull);
    });

    test('returns null for wrong host', () {
      final uri = Uri.parse('authgateway://unknown/client_test_001/info');
      expect(useCase(uri), isNull);
    });

    test('returns null for wrong path', () {
      final uri = Uri.parse('authgateway://clients/client_test_001/activate');
      expect(useCase(uri), isNull);
    });
  });
}
