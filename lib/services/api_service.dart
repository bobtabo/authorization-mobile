import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/client_info.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);
}

class ApiService {
  static const _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

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

  static Future<String> activateClient(String slug, String identifier) async {
    final res = await http.patch(
      Uri.parse(AppConfig.clientStartUrl(slug, identifier)),
      headers: _headers,
    );
    _checkStatus(res);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json['access_token'] as String;
  }

  static Future<void> stopClient(String slug, String identifier) async {
    final res = await http.patch(
      Uri.parse(AppConfig.clientStopUrl(slug, identifier)),
      headers: _headers,
    );
    _checkStatus(res);
  }

  static Future<void> resumeClient(String slug, String identifier) async {
    final res = await http.patch(
      Uri.parse(AppConfig.clientStartUrl(slug, identifier)),
      headers: _headers,
    );
    _checkStatus(res);
  }

  static void _checkStatus(http.Response res) {
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, res.body);
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
