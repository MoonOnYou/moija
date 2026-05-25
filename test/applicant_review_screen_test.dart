import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/data/meeting_repository.dart';
import 'package:moija/features/chat/chat_preview.dart' show pendingApplicantsFor;
import 'package:moija/features/meeting/applicant_review_screen.dart';
import 'package:moija/models/meeting.dart';
import 'package:moija/models/meeting_category.dart';

Meeting _m(String id, String title) => Meeting(
      id: id,
      title: title,
      category: MeetingCategory.cafe,
      startTime: DateTime(2026, 5, 26, 18, 0),
      location: '강남 카페',
      region: '강남',
      locationId: 'seoul-line2',
      currentMembers: 3,
      maxMembers: 6,
    );

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('AppBar에 신청자 수가 보이고, 카드마다 거절/수락 버튼이 있다', (tester) async {
    final m = _m('rev-1', '리뷰 모임');
    final repo = MeetingRepository.test(
      meetings: [m],
      joined: {'rev-1'},
      hosted: {'rev-1'},
    );
    final expected = pendingApplicantsFor(m);

    await tester.pumpWidget(_wrap(
      ApplicantReviewScreen(repository: repo, meeting: m),
    ));
    await tester.pumpAndSettle();

    expect(find.text('신청자 $expected명'), findsOneWidget);
    expect(find.text('거절'), findsNWidgets(expected));
    expect(find.text('수락'), findsNWidgets(expected));
    // 활동/나와 만남 표기가 카드마다 노출된다.
    expect(find.textContaining('년생'), findsNWidgets(expected));
    expect(find.textContaining('활동'), findsNWidgets(expected));
  });

  testWidgets('수락 버튼을 누르면 해당 카드가 사라지고 카운트가 줄어든다', (tester) async {
    final m = _m('rev-2', '리뷰 모임 둘');
    final repo = MeetingRepository.test(
      meetings: [m],
      joined: {'rev-2'},
      hosted: {'rev-2'},
    );
    final initial = pendingApplicantsFor(m);

    await tester.pumpWidget(_wrap(
      ApplicantReviewScreen(repository: repo, meeting: m),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('수락').first);
    await tester.pumpAndSettle();

    if (initial > 1) {
      expect(find.text('신청자 ${initial - 1}명'), findsOneWidget);
      expect(find.text('수락'), findsNWidgets(initial - 1));
    } else {
      expect(find.text('신청자 검토'), findsOneWidget);
      expect(find.text('처리할 신청자가 없어요'), findsOneWidget);
    }
  });

  testWidgets('모든 신청자를 처리하면 빈 상태 안내가 노출된다', (tester) async {
    final m = _m('rev-3', '리뷰 모임 셋');
    final repo = MeetingRepository.test(
      meetings: [m],
      joined: {'rev-3'},
      hosted: {'rev-3'},
    );
    final initial = pendingApplicantsFor(m);

    await tester.pumpWidget(_wrap(
      ApplicantReviewScreen(repository: repo, meeting: m),
    ));
    await tester.pumpAndSettle();

    for (var i = 0; i < initial; i++) {
      await tester.tap(find.text('거절').first);
      await tester.pumpAndSettle();
    }

    expect(find.text('처리할 신청자가 없어요'), findsOneWidget);
    expect(find.text('신청자 검토'), findsOneWidget);
  });
}
