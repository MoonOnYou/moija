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

  // --- 목록 조회 (fetchMeetings) ---

  http.Response _jsonResponse(Object data, int status) => http.Response(
        jsonEncode(data),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Map<String, dynamic> _serverItem({
    String id = 'srv-1',
    String title = '강남 보드게임',
    String category = 'boardGame',
    String startTime = '2026-06-01T19:30:00',
    int currentMembers = 3,
    int maxMembers = 6,
    String costType = 'split',
    int? costAmountWon,
  }) =>
      {
        'id': id,
        'title': title,
        'category': category,
        'custom_category': '',
        'start_time': startTime,
        'location': '강남 보드카페',
        'region': '강남',
        'location_id': 'seoul-line2',
        'max_members': maxMembers,
        'current_members': currentMembers,
        'description': '재밌게 놀아요',
        'nearest_station': '강남역',
        'join_method': 'approval',
        'cost_type': costType,
        'cost_amount_won': costAmountWon,
        'cost_custom_text': '',
      };

  test('fetchMeetings: JSON 배열을 Meeting 리스트로 파싱', () async {
    final client = MockClient((_) async => _jsonResponse([
          _serverItem(),
          _serverItem(
              id: 'srv-2',
              title: '유료 방탈출',
              category: 'escapeRoom',
              costType: 'paid',
              costAmountWon: 22000),
        ], 200));

    final list = await fetchMeetings(
      dateFrom: DateTime(2026, 6, 1),
      dateTo: DateTime(2026, 6, 10),
      client: client,
    );

    expect(list, hasLength(2));
    expect(list[0].id, 'srv-1');
    expect(list[0].title, '강남 보드게임');
    expect(list[0].category, MeetingCategory.boardGame);
    expect(list[0].currentMembers, 3);
    expect(list[0].maxMembers, 6);
    expect(list[0].startTime, DateTime(2026, 6, 1, 19, 30));
    expect(list[1].category, MeetingCategory.escapeRoom);
    expect(list[1].cost.type, CostType.paid);
    expect(list[1].cost.amountWon, 22000);
  });

  test('fetchMeetings: date_from/date_to 쿼리 파라미터 전송', () async {
    late Uri requested;
    final client = MockClient((req) async {
      requested = req.url;
      return _jsonResponse(const [], 200);
    });

    await fetchMeetings(
      dateFrom: DateTime(2026, 5, 31),
      dateTo: DateTime(2026, 7, 20),
      client: client,
    );

    expect(requested.path, '/api/meetings/');
    expect(requested.queryParameters['date_from'], '2026-05-31');
    expect(requested.queryParameters['date_to'], '2026-07-20');
  });

  test('fetchMeetings: 단일 date 파라미터 전송', () async {
    late Uri requested;
    final client = MockClient((req) async {
      requested = req.url;
      return _jsonResponse(const [], 200);
    });

    await fetchMeetings(date: DateTime(2026, 6, 5), client: client);

    expect(requested.queryParameters['date'], '2026-06-05');
    expect(requested.queryParameters.containsKey('date_from'), isFalse);
  });

  test('fetchMeetings: 비-2xx 응답이면 Exception', () {
    final client = MockClient((_) async => http.Response('bad', 400));
    expect(
      fetchMeetings(date: DateTime(2026, 6, 5), client: client),
      throwsException,
    );
  });

  // --- 상세 조회 (fetchMeetingDetail) ---

  test('fetchMeetingDetail: 단일 Meeting 파싱 + 경로에 id 포함', () async {
    late Uri requested;
    final client = MockClient((req) async {
      requested = req.url;
      return _jsonResponse(_serverItem(id: 'abc-123', title: '상세 모임'), 200);
    });

    final m = await fetchMeetingDetail('abc-123', client: client);

    expect(requested.path, '/api/meetings/abc-123/');
    expect(m.id, 'abc-123');
    expect(m.title, '상세 모임');
  });

  test('fetchMeetingDetail: 404면 Exception', () {
    final client = MockClient((_) async => http.Response('not found', 404));
    expect(fetchMeetingDetail('missing', client: client), throwsException);
  });
}
