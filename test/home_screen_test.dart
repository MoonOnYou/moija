import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moija/features/filter/filter_screen.dart';
import 'package:moija/features/home/home_screen.dart';
import 'package:moija/features/home/widgets/day_meetings_pager.dart';
import 'package:moija/features/meeting/diamond_recharge_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the single-month label for the initial window',
      (tester) async {
    await pump(tester);
    expect(find.text('2026년 5월'), findsOneWidget);
  });

  testWidgets('summary shows filter and meeting counts', (tester) async {
    await pump(tester);
    expect(find.text('필터 0개 · 모임 2개'), findsOneWidget);
  });

  testWidgets('tapping a future day updates the meeting list', (tester) async {
    await pump(tester);
    expect(find.text('퇴근 후 볼링'), findsOneWidget);
    await tester.tap(find.text('19'));
    await tester.pumpAndSettle();
    expect(find.text('방탈출 호러 테마 같이!'), findsOneWidget);
    expect(find.text('퇴근 후 볼링'), findsNothing);
  });

  testWidgets('past days are dimmed', (tester) async {
    await pump(tester);
    expect(
      find.byWidgetPredicate((w) => w is Opacity && w.opacity == 0.45),
      findsWidgets,
    );
  });

  testWidgets('swiping the meeting list moves to the next day',
      (tester) async {
    await pump(tester);
    expect(find.text('퇴근 후 볼링'), findsOneWidget);
    await tester.fling(
        find.byType(DayMeetingsPager), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.textContaining('5월 17일'), findsOneWidget);
    expect(find.text('주말 관악산 등반'), findsOneWidget);
  });

  testWidgets('tapping the filter bar opens the FilterScreen', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('filter-bar')));
    await tester.pumpAndSettle();
    expect(find.byType(FilterScreen), findsOneWidget);
  });

  testWidgets('applying a category filter hides non-matching meetings',
      (tester) async {
    await pump(tester);
    expect(find.text('퇴근 후 볼링'), findsOneWidget);
    expect(find.text('불금 한잔'), findsOneWidget);

    await tester.tap(find.byKey(const Key('filter-bar')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('볼링'));
    await tester.pump();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(find.text('퇴근 후 볼링'), findsOneWidget);
    expect(find.text('불금 한잔'), findsNothing);
  });

  testWidgets('restores a persisted filter on launch', (tester) async {
    SharedPreferences.setMockInitialValues({
      'meeting_filter': jsonEncode({
        'categories': ['bowling'],
      }),
    });
    await pump(tester);
    expect(find.text('퇴근 후 볼링'), findsOneWidget);
    expect(find.text('불금 한잔'), findsNothing);
  });

  testWidgets('tapping the diamond chip opens the recharge screen',
      (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('header-diamond')));
    await tester.pumpAndSettle();
    expect(find.byType(DiamondRechargeScreen), findsOneWidget);
  });

  testWidgets('FAB 탭하면 모임 만들기 화면으로 이동', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('모임 만들기'), findsWidgets);
  });
}
