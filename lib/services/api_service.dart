// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/client_info.dart';

/// APIレスポンスが200以外の場合にスローされる例外。
class ApiException implements Exception {
  /// HTTPステータスコード。
  final int statusCode;

  /// リクエストURLとレスポンスボディを含むメッセージ。
  final String message;

  const ApiException(this.statusCode, this.message);
}

/// バックエンドAPIとの通信を担うサービスクラス。
class ApiService {
  static const _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// クライアント情報をAPIから取得する。
  static Future<ClientInfo> fetchClientInfo(
    String slug,
    String identifier,
  ) async {
    final res = await http.get(
      Uri.parse(AppConfig.clientInfoUrl(slug, identifier)),
      headers: _headers,
    );
    _checkStatus(res);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return ClientInfo(
      name: json['name'] as String,
      identifier: json['identifier'] as String,
      status: _parseStatus(json['status'] as int),
    );
  }

  /// 利用開始APIを呼び出し、アクセストークンを返す。
  static Future<String> activateClient(String slug, String identifier) async {
    final res = await http.patch(
      Uri.parse(AppConfig.clientStartUrl(slug, identifier)),
      headers: _headers,
    );
    _checkStatus(res);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json['access_token'] as String;
  }

  /// 利用停止APIを呼び出す。
  static Future<void> stopClient(String slug, String identifier) async {
    final res = await http.patch(
      Uri.parse(AppConfig.clientStopUrl(slug, identifier)),
      headers: _headers,
    );
    _checkStatus(res);
  }

  /// 利用再開APIを呼び出す。
  static Future<void> resumeClient(String slug, String identifier) async {
    final res = await http.patch(
      Uri.parse(AppConfig.clientStartUrl(slug, identifier)),
      headers: _headers,
    );
    _checkStatus(res);
  }

  static void _checkStatus(http.Response res) {
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, '${res.request?.url} ${res.body}');
    }
  }

  // ClientStatus: Pending=0, Inactive=1, Active=2, Suspended=3, Closed=4
  static ClientStatus _parseStatus(int value) {
    return switch (value) {
      2 => ClientStatus.active,
      3 => ClientStatus.suspended,
      _ => ClientStatus.preparing,
    };
  }
}
