// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'client_info.freezed.dart';

/// クライアントの利用状態を表す列挙型。
enum ClientStatus { preparing, active, suspended }

/// [ClientStatus] に表示ラベルを追加する拡張。
extension ClientStatusLabel on ClientStatus {
  /// 画面表示用の日本語ラベル。
  String get label {
    switch (this) {
      case ClientStatus.preparing:
        return '準備中';
      case ClientStatus.active:
        return '利用中';
      case ClientStatus.suspended:
        return '停止中';
    }
  }
}

/// クライアントの基本情報を保持するEntity。
@freezed
abstract class ClientInfo with _$ClientInfo {
  const factory ClientInfo({
    /// クライアント名。
    required String name,

    /// クライアント識別子。
    required String identifier,

    /// メールアドレス。APIレスポンスに含まれない場合は空文字。
    @Default('') String email,

    /// 現在の利用状態。
    required ClientStatus status,
  }) = _ClientInfo;
}
