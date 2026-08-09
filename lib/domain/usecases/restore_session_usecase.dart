// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import '../../core/result.dart';
import '../entities/client_info.dart';
import '../repositories/client_repository.dart';
import '../repositories/client_session_repository.dart';

/// 保存済みセッションからクライアント情報を復元するUseCase。
///
/// セッションが無ければ `null`。取得結果が `active`/`suspended` でなければ
/// セッションを破棄して `null` を返す。通信失敗時（[Err]）は、セッションは
/// 破棄せず `null` を返す（一時的なネットワーク不調でセッションを失わないため。
/// 旧 `main.dart` の `_restoreSession` の `catch` ブロックの挙動を踏襲）。
class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._clientRepository, this._sessionRepository);

  final ClientRepository _clientRepository;
  final ClientSessionRepository _sessionRepository;

  Future<ClientInfo?> call() async {
    final session = await _sessionRepository.loadSession();
    if (session == null) return null;

    final result = await _clientRepository.fetchClientInfo(
      session.slug,
      session.identifier,
    );

    return switch (result) {
      Err() => null,
      Ok(:final value)
          when value.status == ClientStatus.active ||
              value.status == ClientStatus.suspended =>
        value,
      Ok() => await _clearAndReturnNull(),
    };
  }

  Future<ClientInfo?> _clearAndReturnNull() async {
    await _sessionRepository.clearSession();
    return null;
  }
}
