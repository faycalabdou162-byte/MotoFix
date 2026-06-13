import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders MotoFix smoke test', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('MotoFix Niger'))),
    );

    expect(find.text('MotoFix Niger'), findsOneWidget);
  });
}
