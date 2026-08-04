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

    test('compares by value', () {
      expect(Ok<int>(1 + 1), Ok<int>(2));
      expect(Ok<int>(1 + 1).hashCode, Ok<int>(2).hashCode);
      expect(Ok<int>(2), isNot(Ok<int>(3)));
      expect(Ok<num>(2), isNot(Ok<int>(2)));
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

    test('compares by value', () {
      expect(
        Err<int>(ApiFailure(400 + 4, 'not found')),
        Err<int>(ApiFailure(404, 'not found')),
      );
      expect(
        Err<int>(ApiFailure(400 + 4, 'not found')).hashCode,
        Err<int>(ApiFailure(404, 'not found')).hashCode,
      );
      expect(
        Err<int>(ApiFailure(404, 'not found')),
        isNot(Err<int>(NetworkException())),
      );
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

    test('compares by value', () {
      expect(ApiFailure(400 + 4, 'not found'), ApiFailure(404, 'not found'));
      expect(
        ApiFailure(400 + 4, 'not found').hashCode,
        ApiFailure(404, 'not found').hashCode,
      );
      expect(ApiFailure(404, 'not found'), isNot(ApiFailure(500, 'not found')));
      expect(NetworkException('${'通信'}エラー'), NetworkException('通信エラー'));
      expect(UnknownException('${'不明'}なエラー'), UnknownException('不明なエラー'));
      expect(NetworkException('同一文言'), isNot(UnknownException('同一文言')));
    });
  });
}
