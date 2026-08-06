// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import '../entities/backend_option.dart';

/// 選択中バックエンドの永続化を担うRepositoryインターフェース。
///
/// ローカル永続化のみでネットワークを介さないため、[Result] でラップしない。
abstract interface class BackendRepository {
  /// 保存済みの選択中バックエンドを読み込む。
  Future<BackendOption> loadSelected();

  /// 選択中バックエンドを保存する。
  Future<void> saveSelected(BackendOption backend);
}
