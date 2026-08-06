// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

/// クライアントのセッション（利用中のslug/identifier）の永続化を担うRepositoryインターフェース。
///
/// ローカル永続化のみでネットワークを介さないため、[Result] でラップしない。
abstract interface class ClientSessionRepository {
  /// 保存済みのセッションを読み込む。存在しなければ `null`。
  Future<({String slug, String identifier})?> loadSession();

  /// セッションを保存する。
  Future<void> saveSession(String slug, String identifier);

  /// セッションを削除する。
  Future<void> clearSession();
}
