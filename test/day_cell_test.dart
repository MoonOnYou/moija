import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/features/home/widgets/day_cell.dart';
import 'package:moija/models/meeting.dart';
import 'package:moija/models/meeting_category.dart';

Meeting _meeting(int i) => Meeting(
      id: '$i',
      title: '모임$i',
      category: MeetingCategory.etc,
      startTime: DateTime(2026, 5, 20, 19),
      location: '신림 어딘가',
      region: '신림',
      locationId: 'seoul-line2',
      currentMembers: 1,
      maxMembers: 4,
    );

Widget _host(List<Meeting> meetings) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 50,
            height: 104,
            child: DayCell(
              date: DateTime(2026, 5, 20),
              meetings: meetings,
              isPast: false,
              isToday: false,
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('shows +N when meetings exceed available chip slots',
      (tester) async {
    await tester.pumpWidget(_host(List.generate(6, _meeting)));
    expect(find.textContaining('+'), findsOneWidget);
  });

  testWidgets('shows no +N when a single meeting fits', (tester) async {
    await tester.pumpWidget(_host([_meeting(0)]));
    expect(find.textContaining('+'), findsNothing);
  });
}
