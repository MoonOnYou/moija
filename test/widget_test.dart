import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/main.dart';

void main() {
  testWidgets('app builds', (tester) async {
    await tester.pumpWidget(const MoijaApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
