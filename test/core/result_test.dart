import 'package:authorization_mobile/core/errors/app_exception.dart';
import 'package:authorization_mobile/core/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ok', () {
    test('holds the success value', () {
      const result = Ok<int>(42);

      expect(result.value, 42);
    });

    test('matches via switch pattern', () {
      const Result<int> result = Ok<int>(42);

      final matched = switch (result) {
        Ok(:final value) => value,
        Err() => -1,
      };

      expect(matched, 42);
    });
  });

  group('Err', () {
    test('holds the error', () {
      const error = NetworkException();
      const result = Err<int>(error);

      expect(result.error, error);
    });

    test('matches via switch pattern', () {
      const Result<int> result = Err<int>(ApiFailure(404, 'not found'));

      final matched = switch (result) {
        Ok() => null,
        Err(:final error) => error,
      };

      expect(matched, isA<ApiFailure>());
      expect((matched as ApiFailure).statusCode, 404);
    });
  });

  group('AppException', () {
    test('NetworkException has a default message', () {
      expect(const NetworkException().message, '通信エラーが発生しました');
    });

    test('ApiFailure carries statusCode and message', () {
      const error = ApiFailure(500, 'server error');

      expect(error.statusCode, 500);
      expect(error.message, 'server error');
    });

    test('UnknownException has a default message', () {
      expect(const UnknownException().message, '不明なエラーが発生しました');
    });
  });
}
