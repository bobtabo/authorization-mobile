// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import '../../core/result.dart';
import '../entities/client_info.dart';

/// クライアント情報の取得・利用開始/停止/再開を担うRepositoryインターフェース。
///
/// ネットワーク境界を持つため、すべてのメソッドが [Result] を返す。
abstract interface class ClientRepository {
  /// クライアント情報を取得する。
  Future<Result<ClientInfo>> fetchClientInfo(String slug, String identifier);

  /// 利用を開始し、アクセストークンを返す。
  Future<Result<String>> activateClient(String slug, String identifier);

  /// 利用を停止する。
  Future<Result<void>> stopClient(String slug, String identifier);

  /// 利用を再開する。
  Future<Result<void>> resumeClient(String slug, String identifier);
}
