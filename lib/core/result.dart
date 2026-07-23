// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'errors/app_exception.dart';

/// Repository境界での成功/失敗を表す型。
///
/// 呼び出し側は `switch (result) { Ok(:final value) => ..., Err(:final error) => ... }`
/// のようにパターンマッチで分岐する。
sealed class Result<T> {
  const Result();
}

/// 成功時の結果。
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  /// 成功時の値。
  final T value;
}

/// 失敗時の結果。
final class Err<T> extends Result<T> {
  const Err(this.error);

  /// 失敗の内容。
  final AppException error;
}
