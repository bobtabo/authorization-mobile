import 'package:flutter_test/flutter_test.dart';
import 'package:authorization_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AuthorizationGatewayApp());
    expect(find.text('QRコードをスキャン'), findsOneWidget);
  });
}
