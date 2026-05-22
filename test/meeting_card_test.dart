import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/features/home/widgets/meeting_card.dart';
import 'package:moija/models/meeting.dart';
import 'package:moija/models/meeting_category.dart';
import 'package:moija/models/meeting_cost.dart';

void main() {
  Meeting build() => Meeting(
        id: '1',
        title: '강남 보드게임 한판',
        category: MeetingCategory.boardGame,
        startTime: DateTime(2026, 5, 22, 19, 0),
        location: '강남 보드카페',
        region: '강남',
        locationId: 'seoul-line2',
        currentMembers: 2,
        maxMembers: 6,
        nearestStation: '강남 인근',
        cost: const MeetingCost(CostType.split),
      );

  testWidgets('카드는 상세와 동일한 장소(인근역 포함)와 비용을 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: MeetingCard(meeting: build()))),
    );

    // 인근역 + 장소가 함께 보인다.
    expect(find.text('강남 인근 · 강남 보드카페'), findsOneWidget);
    // 비용도 카드에 보인다.
    expect(find.text('더치페이'), findsOneWidget);
  });
}
