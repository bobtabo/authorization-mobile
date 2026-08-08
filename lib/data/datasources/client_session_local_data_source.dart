// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'client_session_local_data_source.g.dart';

/// クライアントセッション（スラッグと識別子）を SharedPreferences に永続化するDataSource。
class ClientSessionLocalDataSource {
  static const _keyIdentifier = 'client_identifier';
  static const _keySlug = 'client_slug';

  /// 保存済みのセッションを読み込む。未保存の場合は null を返す。
  Future<({String slug, String identifier})?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final identifier = prefs.getString(_keyIdentifier);
    final slug = prefs.getString(_keySlug);
    if (identifier == null || slug == null) return null;
    return (slug: slug, identifier: identifier);
  }

  /// スラッグと識別子を保存する。
  ///
  /// 両方の書き込みが成功して初めて有効なセッションと見なす。片方でも失敗した
  /// 場合、[load] が古いスラッグ/識別子と新しい方を組み合わせて返してしまわない
  /// よう、保存済みのセッションを削除しておく。
  Future<void> save(String slug, String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    final slugOk = await prefs.setString(_keySlug, slug);
    final identifierOk = await prefs.setString(_keyIdentifier, identifier);
    if (!slugOk || !identifierOk) {
      debugPrint('[ClientSessionLocalDataSource] failed to save session');
      await prefs.remove(_keySlug);
      await prefs.remove(_keyIdentifier);
    }
  }

  /// 保存済みセッションを削除する。
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIdentifier);
    await prefs.remove(_keySlug);
  }
}

@riverpod
ClientSessionLocalDataSource clientSessionLocalDataSource(Ref ref) =>
    ClientSessionLocalDataSource();
