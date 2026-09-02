// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import '../../core/result.dart';
import '../repositories/client_repository.dart';

/// 利用を停止するUseCase。
class StopClientUseCase {
  const StopClientUseCase(this._repository);

  final ClientRepository _repository;

  Future<Result<void>> call(String slug, String identifier) =>
      _repository.stopClient(slug, identifier);
}
