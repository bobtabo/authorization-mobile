// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/config/app_config.dart';
import '../../domain/entities/client_info.dart';

part 'client_remote_data_source.g.dart';

/// APIレスポンスが200以外の場合にスローされる例外。
class ApiException implements Exception {
  /// HTTPステータスコード。
  final int statusCode;

  /// リクエストURLとレスポンスボディを含むメッセージ。
  final String message;

  const ApiException(this.statusCode, this.message);
}

/// バックエンドAPIとの通信を担うDataSource。
class ClientRemoteDataSource {
  ClientRemoteDataSource({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  /// HTTP通信に使用するクライアント。
  ///
  /// 通常は実際の [http.Client] を使うが、テストやデモ（integration_test）では
  /// `package:http/testing.dart` の `MockClient` をコンストラクタで渡すことで
  /// API応答をモックできる。差し替えは本番の呼び出し方には影響しない。
  final http.Client _client;

  /// このインスタンスが `_client` を自ら生成したか（＝解放の責任を持つか）。
  /// 外部から渡された場合は呼び出し元が管理するため閉じない。
  final bool _ownsClient;

  static const _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// 各リクエストの上限時間。バックエンドが応答不能な場合に無期限で
  /// ローディング状態のままにならないようにする。
  static const _timeout = Duration(seconds: 15);

  /// クライアント情報をAPIから取得する。
  Future<ClientInfo> fetchClientInfo(String slug, String identifier) async {
    final res = await _client
        .get(
          Uri.parse(AppConfig.clientInfoUrl(slug, identifier)),
          headers: _headers,
        )
        .timeout(_timeout);
    _checkStatus(res);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return ClientInfo(
      name: json['name'] as String,
      identifier: json['identifier'] as String,
      email: json['email'] as String? ?? '',
      status: _parseStatus(json['status'] as int),
    );
  }

  /// 利用開始APIを呼び出し、アクセストークンを返す。
  Future<String> activateClient(String slug, String identifier) async {
    final res = await _client
        .patch(
          Uri.parse(AppConfig.clientStartUrl(slug, identifier)),
          headers: _headers,
        )
        .timeout(_timeout);
    _checkStatus(res);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json['access_token'] as String;
  }

  /// 利用停止APIを呼び出す。
  Future<void> stopClient(String slug, String identifier) async {
    final res = await _client
        .patch(
          Uri.parse(AppConfig.clientStopUrl(slug, identifier)),
          headers: _headers,
        )
        .timeout(_timeout);
    _checkStatus(res);
  }

  /// 利用再開APIを呼び出す。
  Future<void> resumeClient(String slug, String identifier) async {
    final res = await _client
        .patch(
          Uri.parse(AppConfig.clientStartUrl(slug, identifier)),
          headers: _headers,
        )
        .timeout(_timeout);
    _checkStatus(res);
  }

  /// 自ら生成した [_client] を解放する。
  void close() {
    if (_ownsClient) _client.close();
  }

  void _checkStatus(http.Response res) {
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, '${res.request?.url} ${res.body}');
    }
  }

  // ClientStatus: Pending=0, Inactive=1, Active=2, Suspended=3, Closed=4
  ClientStatus _parseStatus(int value) {
    return switch (value) {
      2 => ClientStatus.active,
      3 => ClientStatus.suspended,
      _ => ClientStatus.preparing,
    };
  }
}

@riverpod
ClientRemoteDataSource clientRemoteDataSource(Ref ref) {
  final dataSource = ClientRemoteDataSource();
  ref.onDispose(dataSource.close);
  return dataSource;
}
