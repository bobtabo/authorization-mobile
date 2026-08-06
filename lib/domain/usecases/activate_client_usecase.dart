// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import '../../core/result.dart';
import '../repositories/client_repository.dart';

/// 利用を開始し、アクセストークンを返すUseCase。
class ActivateClientUseCase {
  const ActivateClientUseCase(this._repository);

  final ClientRepository _repository;

  Future<Result<String>> call(String slug, String identifier) =>
      _repository.activateClient(slug, identifier);
}
