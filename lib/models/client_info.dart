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

/// クライアントの基本情報を保持するモデル。
class ClientInfo {
  /// クライアント名。
  final String name;

  /// クライアント識別子。
  final String identifier;

  /// メールアドレス。APIレスポンスに含まれない場合は空文字。
  final String email;

  /// 現在の利用状態。
  final ClientStatus status;

  const ClientInfo({
    required this.name,
    required this.identifier,
    this.email = '',
    required this.status,
  });

  /// 指定フィールドを上書きした新しいインスタンスを返す。
  ClientInfo copyWith({
    String? name,
    String? identifier,
    String? email,
    ClientStatus? status,
  }) {
    return ClientInfo(
      name: name ?? this.name,
      identifier: identifier ?? this.identifier,
      email: email ?? this.email,
      status: status ?? this.status,
    );
  }
}
