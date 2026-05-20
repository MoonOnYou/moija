import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/features/home/home_screen.dart';
import 'package:moija/features/home/widgets/two_week_calendar.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  }

  testWidgets('shows the single-month label for the initial window',
      (tester) async {
    await pump(tester);
    expect(find.text('2026년 5월'), findsOneWidget);
  });

  testWidgets('tapping a day updates the meeting list', (tester) async {
    await pump(tester);
    expect(find.text('퇴근 후 볼링'), findsOneWidget);

    await tester.tap(find.text('19'));
    await tester.pumpAndSettle();
    expect(find.text('방탈출 호러 테마 같이!'), findsOneWidget);
    expect(find.text('퇴근 후 볼링'), findsNothing);
  });

  testWidgets('selecting an empty day shows the empty state', (tester) async {
    await pump(tester);
    await tester.tap(find.text('18'));
    await tester.pumpAndSettle();
    expect(find.text('모임 0개'), findsOneWidget);
    expect(find.text('이 날에는 모임이 없어요'), findsOneWidget);
  });

  testWidgets('swiping pages the window by two weeks', (tester) async {
    await pump(tester);
    await tester.fling(
        find.byType(TwoWeekCalendar), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('2026년 5–6월'), findsOneWidget);
  });

  testWidgets('past days are dimmed', (tester) async {
    await pump(tester);
    expect(
      find.byWidgetPredicate((w) => w is Opacity && w.opacity == 0.45),
      findsWidgets,
    );
  });
}
