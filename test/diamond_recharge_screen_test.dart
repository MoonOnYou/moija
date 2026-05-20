import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/features/meeting/diamond_recharge_screen.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
      home: DiamondRechargeScreen(currentDiamonds: 30),
    ));
  }

  testWidgets('shows balance, packages, and default payment amount',
      (tester) async {
    await pump(tester);

    expect(find.text('현재 보유'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('1,000 다이아'), findsOneWidget);
    expect(find.text('3,300 다이아'), findsOneWidget);
    expect(find.text('12,000 다이아'), findsOneWidget);
    expect(find.text('광고 보고 무료 충전'), findsOneWidget);
    expect(find.text('₩3,000 결제하기'), findsOneWidget);
  });

  testWidgets('selecting another package updates the payment amount',
      (tester) async {
    await pump(tester);

    await tester.tap(find.text('12,000 다이아'));
    await tester.pump();

    expect(find.text('₩10,000 결제하기'), findsOneWidget);
  });
}
