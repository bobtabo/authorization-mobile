enum ClientStatus { preparing, active, suspended }

extension ClientStatusLabel on ClientStatus {
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

class ClientInfo {
  final String name;
  final String identifier;
  final String email;
  final ClientStatus status;

  const ClientInfo({
    required this.name,
    required this.identifier,
    required this.email,
    required this.status,
  });

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
