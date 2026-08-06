// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import '../entities/backend_option.dart';
import '../repositories/backend_repository.dart';

/// 保存済みの選択中バックエンドを読み込むUseCase。
class LoadSavedBackendUseCase {
  const LoadSavedBackendUseCase(this._repository);

  final BackendRepository _repository;

  Future<BackendOption> call() => _repository.loadSelected();
}
