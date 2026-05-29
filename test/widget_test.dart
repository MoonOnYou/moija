import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/main.dart';
import 'package:moija/features/home/home_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  testWidgets('splash → HomeScreen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MoijaApp());
    // 스플래시가 먼저 뜬다(따뜻한 한 줄 소개).
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('혼자보다 함께라서 더 즐거운 하루'), findsOneWidget);
    // 스플래시 타이머(2s) + 페이드 전환(450ms) 경과 후 홈으로.
    // 무한 회전 인디케이터가 있어 pumpAndSettle 대신 명시적으로 진행한다.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('모이자'), findsOneWidget);
  });
}
