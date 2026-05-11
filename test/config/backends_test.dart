import 'package:flutter_test/flutter_test.dart';
import 'package:authorization_mobile/config/backends.dart';

void main() {
  group('kBackends', () {
    test('contains 10 backends', () {
      expect(kBackends.length, 10);
    });

    test('has no duplicate slugs', () {
      final slugs = kBackends.map((b) => b.slug).toList();
      expect(slugs.toSet().length, equals(slugs.length));
    });

    test('all entries have non-empty name and slug', () {
      for (final b in kBackends) {
        expect(b.name, isNotEmpty);
        expect(b.slug, isNotEmpty);
      }
    });

    test('kDefaultBackend is included', () {
      expect(kBackends.any((b) => b.slug == kDefaultBackend.slug), isTrue);
    });
  });

  group('kDefaultBackend', () {
    test('slug is php', () {
      expect(kDefaultBackend.slug, 'php');
    });

    test('name is PHP', () {
      expect(kDefaultBackend.name, 'PHP');
    });
  });
}
