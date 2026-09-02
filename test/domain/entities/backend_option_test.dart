import 'package:authorization_mobile/domain/entities/backend_option.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackendOption', () {
    test('compares by value', () {
      expect(
        const BackendOption(name: 'PHP', slug: 'php'),
        const BackendOption(name: 'PHP', slug: 'php'),
      );
      expect(
        const BackendOption(name: 'PHP', slug: 'php'),
        isNot(const BackendOption(name: 'Go (Gin)', slug: 'go-gin')),
      );
    });

    test('copyWith updates a single field', () {
      const base = BackendOption(name: 'PHP', slug: 'php');
      final updated = base.copyWith(slug: 'php2');

      expect(updated.name, 'PHP');
      expect(updated.slug, 'php2');
    });
  });
}
