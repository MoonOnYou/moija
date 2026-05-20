import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/data/meeting_repository.dart';
import 'package:moija/features/meeting/meeting_detail_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  testWidgets('renders meeting info, participants, and join CTA',
      (tester) async {
    final repo = MeetingRepository();
    final meeting = repo.allMeetings.firstWhere((m) => m.id == 't1');
    await tester.pumpWidget(MaterialApp(
      home: MeetingDetailScreen(meeting: meeting, repository: repo),
    ));
    await tester.pumpAndSettle();

    expect(find.text('퇴근 후 볼링'), findsOneWidget);
    expect(find.text('참가 신청하기'), findsOneWidget);
    expect(find.text('방장이 수락할 경우 다이아 50개 차감'), findsOneWidget);
    expect(find.text('참가자 4명'), findsOneWidget);
    expect(find.text('모집중'), findsOneWidget);
    expect(find.text('HOST'), findsOneWidget);
    expect(find.textContaining('나와'), findsWidgets);
  });
}
