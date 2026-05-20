import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/features/home/home_screen.dart';
import 'package:moija/features/home/widgets/month_calendar.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  // 실제 휴대폰 뷰포트(390x844)로 렌더한다. 기본 800x600(데스크톱)에서는
  // 헤더+필터+6주 캘린더+요약+리스트가 세로로 넘쳐 오버플로가 난다.
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  }

  testWidgets('shows the fixed-today month label', (tester) async {
    await pump(tester);
    expect(find.text('2026년 5월'), findsOneWidget);
  });

  testWidgets('tapping a day updates the meeting list', (tester) async {
    await pump(tester);
    // 기본 선택일은 오늘(5/16) → "퇴근 후 볼링"이 보인다.
    expect(find.text('퇴근 후 볼링'), findsOneWidget);

    // 5월 19일 셀 탭 → "방탈출 호러 테마 같이!"로 갱신.
    await tester.tap(find.text('19'));
    await tester.pumpAndSettle();
    expect(find.text('방탈출 호러 테마 같이!'), findsOneWidget);
    expect(find.text('퇴근 후 볼링'), findsNothing);
  });

  testWidgets('month navigation updates the header label', (tester) async {
    await pump(tester);
    await tester.fling(
        find.byType(MonthCalendar), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('2026년 6월'), findsOneWidget);
  });

  testWidgets('selecting a day with no meetings shows the empty state',
      (tester) async {
    await pump(tester);
    // 5월 11일에는 모임이 없다.
    await tester.tap(find.text('11'));
    await tester.pumpAndSettle();
    expect(find.text('모임 0개'), findsOneWidget);
    expect(find.text('이 날에는 모임이 없어요'), findsOneWidget);
  });
}
