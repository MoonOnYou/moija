import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moija/data/api/meeting_api.dart';
import 'package:moija/models/join_method.dart';
import 'package:moija/models/meeting.dart';
import 'package:moija/models/meeting_category.dart';
import 'package:moija/models/meeting_cost.dart';

Meeting _m() => Meeting(
      id: 'local-id',
      title: '카페 모임',
      category: MeetingCategory.cafe,
      startTime: DateTime(2026, 6, 1, 14, 0),
      location: '강남 카페',
      region: '강남',
      locationId: 'seoul-line2',
      currentMembers: 1,
      maxMembers: 4,
      description: '테스트 모임',
      nearestStation: '강남역',
      cost: const MeetingCost(CostType.split),
      joinMethod: JoinMethod.approval,
    );

void main() {
  test('2xx 응답: 예외 없이 반환', () async {
    final client = MockClient((_) async => http.Response('{}', 201));
    await expectLater(createMeeting(_m(), client: client), completes);
  });

  test('올바른 JSON 페이로드 전송', () async {
    late Map<String, dynamic> body;
    final client = MockClient((req) async {
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response('{}', 201);
    });
    await createMeeting(_m(), client: client);

    expect(body['title'], '카페 모임');
    expect(body['category'], 'cafe');
    expect(body['custom_category'], '');
    expect(body['max_members'], 4);
    expect(body['cost_type'], 'split');
    expect(body['join_method'], 'approval');
    expect(body['location_id'], 'seoul-line2');
    expect(body['nearest_station'], '강남역');
    expect(body.containsKey('cost_amount_won'), isFalse);
  });

  test('paid 비용이면 cost_amount_won 포함', () async {
    late Map<String, dynamic> body;
    final client = MockClient((req) async {
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response('{}', 201);
    });
    final m = Meeting(
      id: 'x',
      title: '유료',
      category: MeetingCategory.escapeRoom,
      startTime: DateTime(2026, 6, 1, 20, 0),
      location: '강남',
      region: '강남',
      locationId: 'seoul-line2',
      currentMembers: 1,
      maxMembers: 4,
      cost: const MeetingCost(CostType.paid, amountWon: 22000),
      joinMethod: JoinMethod.approval,
    );
    await createMeeting(m, client: client);
    expect(body['cost_amount_won'], 22000);
  });

  test('4xx 응답: Exception throw', () {
    final client = MockClient((_) async => http.Response('{"error":"bad"}', 400));
    expect(createMeeting(_m(), client: client), throwsException);
  });

  test('5xx 응답: Exception throw', () {
    final client = MockClient((_) async => http.Response('error', 500));
    expect(createMeeting(_m(), client: client), throwsException);
  });
}
