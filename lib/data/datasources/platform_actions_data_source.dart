// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'platform_actions_data_source.g.dart';

/// クリップボード・共有シートなど、プラットフォームSDKの呼び出しを担うDataSource。
class PlatformActionsDataSource {
  /// [text] をクリップボードにコピーする。
  Future<void> copyToClipboard(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  /// [text] を共有シートで共有する。
  ///
  /// [sharePositionOrigin] はiPadのポップオーバー表示位置に使われる。
  /// `BuildContext` に依存する計算のため、呼び出し元（View）で算出して渡す。
  Future<void> share(String text, {required Rect? sharePositionOrigin}) =>
      SharePlus.instance.share(
        ShareParams(
          text: text,
          title: 'アクセストークンをシェア',
          subject: 'アクセストークンをシェア',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
}

@riverpod
PlatformActionsDataSource platformActionsDataSource(Ref ref) =>
    PlatformActionsDataSource();
