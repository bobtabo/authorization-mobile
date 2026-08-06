// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import '../../core/result.dart';
import '../entities/client_info.dart';
import '../repositories/client_repository.dart';

/// クライアント情報を取得するUseCase。
class FetchClientInfoUseCase {
  const FetchClientInfoUseCase(this._repository);

  final ClientRepository _repository;

  Future<Result<ClientInfo>> call(String slug, String identifier) =>
      _repository.fetchClientInfo(slug, identifier);
}
