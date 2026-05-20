import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/data/meeting_repository.dart';
import 'package:moija/features/home/widgets/day_meetings_pager.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  Future<DateTime?> swipe(WidgetTester tester, Offset offset) async {
    DateTime? changed;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayMeetingsPager(
          selectedDay: DateTime(2026, 5, 16),
          repository: MeetingRepository(),
          onDayChanged: (d) => changed = d,
        ),
      ),
    ));
    await tester.fling(find.byType(PageView), offset, 1000);
    await tester.pumpAndSettle();
    return changed;
  }

  testWidgets('swiping left advances to the next day', (tester) async {
    final changed = await swipe(tester, const Offset(-400, 0));
    expect(changed, DateTime(2026, 5, 17));
  });

  testWidgets('swiping right goes to the previous day', (tester) async {
    final changed = await swipe(tester, const Offset(400, 0));
    expect(changed, DateTime(2026, 5, 15));
  });
}
