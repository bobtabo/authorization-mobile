// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'package:shared_preferences/shared_preferences.dart';
import '../config/backends.dart';

/// 選択中バックエンドを SharedPreferences に永続化するサービスクラス。
class BackendService {
  static const _key = 'selected_backend_slug';

  /// 保存済みのバックエンドを読み込む。未保存の場合は [kDefaultBackend] を返す。
  static Future<BackendOption> load() async {
    final prefs = await SharedPreferences.getInstance();
    final slug = prefs.getString(_key);
    if (slug == null) return kDefaultBackend;
    return kBackends.firstWhere(
      (b) => b.slug == slug,
      orElse: () => kDefaultBackend,
    );
  }

  /// 選択中バックエンドを保存する。
  static Future<void> save(BackendOption backend) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, backend.slug);
  }
}
