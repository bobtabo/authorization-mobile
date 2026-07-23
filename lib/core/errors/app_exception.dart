// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

/// アプリ全体で扱うエラー種別の基底クラス。
sealed class AppException {
  const AppException(this.message);

  /// UIに表示するエラーメッセージ。
  final String message;
}

/// ネットワーク通信自体が失敗した場合の例外。
final class NetworkException extends AppException {
  const NetworkException([super.message = '通信エラーが発生しました']);
}

/// APIがエラーレスポンス（200以外）を返した場合の例外。
final class ApiFailure extends AppException {
  const ApiFailure(this.statusCode, super.message);

  /// HTTPステータスコード。
  final int statusCode;
}

/// 上記以外の予期しない例外。
final class UnknownException extends AppException {
  const UnknownException([super.message = '不明なエラーが発生しました']);
}
