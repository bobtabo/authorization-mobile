// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/backends.dart';
import '../../domain/entities/backend_option.dart';

part 'backend_local_data_source.g.dart';

/// 選択中バックエンドを SharedPreferences に永続化するDataSource。
class BackendLocalDataSource {
  static const _key = 'selected_backend_slug';

  /// 保存済みのバックエンドを読み込む。未保存の場合は [kDefaultBackend] を返す。
  Future<BackendOption> load() async {
    final prefs = await SharedPreferences.getInstance();
    final slug = prefs.getString(_key);
    if (slug == null) return kDefaultBackend;
    return kBackends.firstWhere(
      (b) => b.slug == slug,
      orElse: () => kDefaultBackend,
    );
  }

  /// 選択中バックエンドを保存する。
  Future<void> save(BackendOption backend) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, backend.slug);
  }
}

@riverpod
BackendLocalDataSource backendLocalDataSource(Ref ref) =>
    BackendLocalDataSource();
