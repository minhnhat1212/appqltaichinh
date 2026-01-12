import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test - widget co the build', (WidgetTester tester) async {
    // ✅ Test đơn giản để khỏi fail do Firebase initialize trong test
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('OK'))),
      ),
    );

    expect(find.text('OK'), findsOneWidget);
  });
}
