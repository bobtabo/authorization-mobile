// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'backend_option.freezed.dart';

/// バックエンド選択肢を表すEntity。
@freezed
abstract class BackendOption with _$BackendOption {
  const factory BackendOption({
    /// 表示名。
    required String name,

    /// APIゲートウェイのパスセグメントに使用するスラッグ。
    required String slug,
  }) = _BackendOption;
}
