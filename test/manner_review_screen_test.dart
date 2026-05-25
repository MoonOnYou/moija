import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/data/meeting_repository.dart';
import 'package:moija/features/meeting/manner_review_screen.dart';
import 'package:moija/models/meeting.dart';
import 'package:moija/models/meeting_category.dart';

Meeting _m(String id, String title, {int currentMembers = 4}) => Meeting(
      id: id,
      title: title,
      category: MeetingCategory.cafe,
      startTime: DateTime(2026, 5, 25, 18, 0),
      location: '강남 카페',
      region: '강남',
      locationId: 'seoul-line2',
      currentMembers: currentMembers,
      maxMembers: 6,
    );

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('AppBar에 평가 대상 수가 나오고, 호스트는 제외된다', (tester) async {
    final m = _m('m1', '평가 모임', currentMembers: 4); // 호스트 제외 3명
    final repo = MeetingRepository.test(meetings: [m], joined: {'m1'});

    await tester.pumpWidget(_wrap(
      MannerReviewScreen(repository: repo, meeting: m),
    ));
    await tester.pumpAndSettle();

    expect(find.text('매너 평가 3명'), findsOneWidget);
    // 별점/차단/건너뛰기/제출 모두 카드마다 노출.
    expect(find.text('차단'), findsNWidgets(3));
    expect(find.text('건너뛰기'), findsNWidgets(3));
    expect(find.text('제출'), findsNWidgets(3));
    // 안내 텍스트(별점 미선택).
    expect(find.text('별을 눌러 점수를 선택하세요'), findsNWidgets(3));
  });

  testWidgets('별점 누르기 전엔 제출 비활성, 누르면 활성·점수 표시', (tester) async {
    final m = _m('m-star', '별점 시각화', currentMembers: 2); // 호스트 제외 1명
    final repo = MeetingRepository.test(meetings: [m], joined: {'m-star'});

    await tester.pumpWidget(_wrap(
      MannerReviewScreen(repository: repo, meeting: m),
    ));
    await tester.pumpAndSettle();

    final submitBtn = find.widgetWithText(FilledButton, '제출');
    expect(tester.widget<FilledButton>(submitBtn).onPressed, isNull,
        reason: '별점 0일 때 제출 비활성');

    await tester.tap(find.byKey(const ValueKey('star-3')));
    await tester.pump();

    expect(find.text('3점'), findsOneWidget);
    expect(tester.widget<FilledButton>(submitBtn).onPressed, isNotNull);
    // 카드는 아직 사라지지 않음(제출 전).
    expect(find.text('매너 평가 1명'), findsOneWidget);
  });

  testWidgets('별점 후 제출 → 카드 사라지고 카운트가 줄어든다', (tester) async {
    final m = _m('m2', '제출 모임', currentMembers: 3); // 호스트 제외 2명
    final repo = MeetingRepository.test(meetings: [m], joined: {'m2'});

    await tester.pumpWidget(_wrap(
      MannerReviewScreen(repository: repo, meeting: m),
    ));
    await tester.pumpAndSettle();

    expect(find.text('매너 평가 2명'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('star-4')).first);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '제출').first);
    await tester.pumpAndSettle();

    expect(find.text('매너 평가 1명'), findsOneWidget);
  });

  testWidgets('차단·건너뛰기 누르면 카드가 즉시 사라진다', (tester) async {
    final m = _m('m3', '버튼 모임', currentMembers: 3); // 호스트 제외 2명
    final repo = MeetingRepository.test(meetings: [m], joined: {'m3'});

    await tester.pumpWidget(_wrap(
      MannerReviewScreen(repository: repo, meeting: m),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('차단').first);
    await tester.pumpAndSettle();
    expect(find.text('매너 평가 1명'), findsOneWidget);

    await tester.tap(find.text('건너뛰기').first);
    await tester.pumpAndSettle();
    expect(find.text('모두 평가했어요'), findsOneWidget);
    expect(find.text('매너 평가'), findsOneWidget); // AppBar 제목 fallback
  });
}
