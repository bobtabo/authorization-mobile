// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import '../../core/config/backends.dart';

/// QRコードのURIを解析し、スラッグと識別子を返すUseCase。
///
/// 形式: `authgateway://clients/{identifier}/info`
/// 形式が一致しない場合は `null` を返す。
///
/// **重要**: slugは常に [kDefaultBackend] のslugを返す（QRからはidentifierのみ
/// 抽出し、選択中バックエンドは無視する）。この挙動は移植元の
/// `AppConfig.parseQrUri` の仕様通りで、意図的に変更していない。
class ParseQrUseCase {
  const ParseQrUseCase();

  ({String slug, String identifier})? call(Uri uri) {
    if (uri.scheme != 'authgateway' || uri.host != 'clients') return null;
    final match = RegExp(r'^/([^/]+)/info$').firstMatch(uri.path);
    if (match == null) return null;
    return (slug: kDefaultBackend.slug, identifier: match.group(1)!);
  }
}
