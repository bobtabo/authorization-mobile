import 'package:flutter_test/flutter_test.dart';
import 'package:authorization_mobile/models/client_info.dart';

void main() {
  group('ClientStatus.label', () {
    test('preparing returns 準備中', () {
      expect(ClientStatus.preparing.label, '準備中');
    });

    test('active returns 利用中', () {
      expect(ClientStatus.active.label, '利用中');
    });

    test('suspended returns 停止中', () {
      expect(ClientStatus.suspended.label, '停止中');
    });
  });

  group('ClientInfo.copyWith', () {
    const base = ClientInfo(
      name: 'テスト株式会社',
      identifier: 'test_client_001',
      email: 'test@example.com',
      status: ClientStatus.preparing,
    );

    test('updates status while preserving other fields', () {
      final updated = base.copyWith(status: ClientStatus.active);

      expect(updated.name, base.name);
      expect(updated.identifier, base.identifier);
      expect(updated.email, base.email);
      expect(updated.status, ClientStatus.active);
    });

    test('updates name only', () {
      final updated = base.copyWith(name: '新しい株式会社');

      expect(updated.name, '新しい株式会社');
      expect(updated.identifier, base.identifier);
      expect(updated.email, base.email);
      expect(updated.status, base.status);
    });

    test('with no arguments preserves all fields', () {
      final copy = base.copyWith();

      expect(copy.name, base.name);
      expect(copy.identifier, base.identifier);
      expect(copy.email, base.email);
      expect(copy.status, base.status);
    });
  });
}
