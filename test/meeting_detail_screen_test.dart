import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/data/meeting_repository.dart';
import 'package:moija/features/meeting/diamond_recharge_screen.dart';
import 'package:moija/features/meeting/meeting_detail_screen.dart';
import 'package:moija/models/join_method.dart';
import 'package:moija/models/meeting.dart';
import 'package:moija/shell/app_navigation.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  setUp(() {
    selectedTab.value = 0;
    pendingFocusDay.value = null;
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
    // 승인제 모임이므로 CTA는 "참가 신청하기", 참가방식 배지가 보인다.
    expect(find.text('참가 신청하기'), findsOneWidget);
    expect(find.text('승인제'), findsOneWidget);
    // 다이아 차감 안내 문구는 더 이상 노출하지 않는다.
    expect(find.text('방장 수락 시 다이아 50개 차감'), findsNothing);
    expect(find.text('참가자 4명'), findsOneWidget);
    expect(find.text('방장'), findsOneWidget);
  });

  testWidgets('선착순 모임은 CTA가 "모임 참가하기"로, 배지가 "선착순"으로 나온다',
      (tester) async {
    final repo = MeetingRepository();
    final base = repo.allMeetings.firstWhere((m) => m.id == 't1');
    final firstCome = Meeting(
      id: base.id,
      title: base.title,
      category: base.category,
      startTime: base.startTime,
      location: base.location,
      region: base.region,
      locationId: base.locationId,
      currentMembers: base.currentMembers,
      maxMembers: base.maxMembers,
      description: base.description,
      nearestStation: base.nearestStation,
      cost: base.cost,
      joinMethod: JoinMethod.firstCome,
    );
    await tester.pumpWidget(MaterialApp(
      home: MeetingDetailScreen(meeting: firstCome, repository: repo),
    ));
    await tester.pumpAndSettle();

    expect(find.text('모임 참가하기'), findsOneWidget);
    expect(find.text('참가 신청하기'), findsNothing);
    expect(find.text('선착순'), findsOneWidget);
  });

  testWidgets('low balance shows toast and opens recharge screen',
      (tester) async {
    final repo = MeetingRepository();
    final meeting = repo.allMeetings.firstWhere((m) => m.id == 't1');
    await tester.pumpWidget(MaterialApp(
      home: MeetingDetailScreen(
          meeting: meeting, repository: repo, diamonds: 30),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('참가 신청하기'));
    await tester.pumpAndSettle();

    expect(find.byType(DiamondRechargeScreen), findsOneWidget);
    expect(find.text('다이아 50개 이상일 때 참가 신청을 할 수 있어요'), findsOneWidget);
  });

  testWidgets('승인제: 안내 동의 후 신청 완료 토스트 + 내모임 탭으로 이동', (tester) async {
    final repo = MeetingRepository();
    final meeting = repo.allMeetings.firstWhere((m) => m.id == 't1');
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MeetingDetailScreen(
                      meeting: meeting, repository: repo, diamonds: 1000),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // 참가 신청하기 → 승인제 안내(#23b) 노출
    await tester.tap(find.text('참가 신청하기'));
    await tester.pumpAndSettle();
    expect(find.text('참가 신청하기 전에\n확인해주세요'), findsOneWidget);

    // 동의 → 첫 화면으로 복귀 + 토스트 + 내모임 탭(2) 선택
    await tester.tap(find.byKey(const Key('notice-agree')));
    await tester.pumpAndSettle();

    expect(find.byType(MeetingDetailScreen), findsNothing);
    expect(find.text('참가 신청이 완료되었습니다'), findsOneWidget);
    expect(selectedTab.value, 2);
  });

  testWidgets('선착순: 안내 동의 후 채팅 탭으로 이동', (tester) async {
    final repo = MeetingRepository();
    final base = repo.allMeetings.firstWhere((m) => m.id == 't1');
    final firstCome = Meeting(
      id: base.id,
      title: base.title,
      category: base.category,
      startTime: base.startTime,
      location: base.location,
      region: base.region,
      locationId: base.locationId,
      currentMembers: base.currentMembers,
      maxMembers: base.maxMembers,
      description: base.description,
      nearestStation: base.nearestStation,
      cost: base.cost,
      joinMethod: JoinMethod.firstCome,
    );
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MeetingDetailScreen(
                      meeting: firstCome, repository: repo, diamonds: 1000),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('모임 참가하기'));
    await tester.pumpAndSettle();
    expect(find.text('바로 참가하기 전에\n확인해주세요'), findsOneWidget);

    await tester.tap(find.byKey(const Key('notice-agree')));
    await tester.pumpAndSettle();

    expect(find.byType(MeetingDetailScreen), findsNothing);
    expect(selectedTab.value, 1);
  });

  testWidgets('fetchDetail 주입 시 서버 최신값으로 갱신된다', (tester) async {
    final repo = MeetingRepository();
    final base = repo.allMeetings.firstWhere((m) => m.id == 't1');
    final fresh = Meeting(
      id: base.id,
      title: '서버에서 갱신된 제목',
      category: base.category,
      startTime: base.startTime,
      location: base.location,
      region: base.region,
      locationId: base.locationId,
      currentMembers: base.currentMembers,
      maxMembers: base.maxMembers,
      description: base.description,
      nearestStation: base.nearestStation,
      cost: base.cost,
      joinMethod: base.joinMethod,
    );

    await tester.pumpWidget(MaterialApp(
      home: MeetingDetailScreen(
        meeting: base,
        repository: repo,
        fetchDetail: (id) async => fresh,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('서버에서 갱신된 제목'), findsOneWidget);
    expect(find.text('퇴근 후 볼링'), findsNothing);
  });

  testWidgets('fetchDetail 실패 시 전달받은 모임으로 폴백한다', (tester) async {
    final repo = MeetingRepository();
    final base = repo.allMeetings.firstWhere((m) => m.id == 't1');

    await tester.pumpWidget(MaterialApp(
      home: MeetingDetailScreen(
        meeting: base,
        repository: repo,
        fetchDetail: (id) async => throw Exception('network'),
      ),
    ));
    await tester.pumpAndSettle();

    // 실패해도 목록에서 받은 정보가 그대로 보인다.
    expect(find.text('퇴근 후 볼링'), findsOneWidget);
    expect(find.text('참가자 4명'), findsOneWidget);
  });
}
