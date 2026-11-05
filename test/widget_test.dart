import 'package:flutter_test/flutter_test.dart';

import 'package:push_notification_demo/main.dart';

void main() {
  testWidgets('home screen renders without Firebase', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Push Notification Demo'), findsOneWidget);
    expect(find.text('Not configured'), findsOneWidget);
    expect(find.text('Quick test (no server)'), findsOneWidget);
  });
}
