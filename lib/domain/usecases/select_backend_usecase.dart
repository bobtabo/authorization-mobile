// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import '../entities/backend_option.dart';
import '../repositories/backend_repository.dart';

/// 選択中バックエンドを保存するUseCase。
class SelectBackendUseCase {
  const SelectBackendUseCase(this._repository);

  final BackendRepository _repository;

  Future<void> call(BackendOption backend) => _repository.saveSelected(backend);
}
