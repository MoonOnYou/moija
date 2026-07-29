import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/meeting.dart';
import '../auth/auth_store.dart';
import '../current_user.dart';

/// 서버 베이스 URL. 빌드 시 `--dart-define=API_BASE_URL=...`로 덮어쓸 수 있다.
/// 안드로이드 실기기/에뮬레이터에서 Mac의 로컬 서버에 붙으려면
/// `adb reverse tcp:8000 tcp:8000` 후 기본값(localhost)을 그대로 쓰거나,
/// 에뮬레이터는 `--dart-define=API_BASE_URL=http://10.0.2.2:8000`을 쓴다.
const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

Future<void> createMeeting(Meeting m, {@visibleForTesting http.Client? client}) async {
  final c = client ?? http.Client();
  try {
    final body = <String, dynamic>{
      'title': m.title,
      'category': m.category.name,
      'custom_category': m.customCategory,
      'start_time': m.startTime.toIso8601String(),
      'location': m.location,
      'region': m.region,
      'location_id': m.locationId,
      'max_members': m.maxMembers,
      'description': m.description,
      'nearest_station': m.nearestStation,
      'join_method': m.joinMethod.name,
      'cost_type': m.cost.type.name,
      if (m.cost.amountWon != null) 'cost_amount_won': m.cost.amountWon,
      'cost_custom_text': m.cost.customText ?? '',
      // 로그인 사용자를 방장으로 보낸다. 서버는 host를 필수로 요구한다.
      // 미로그인 시에는 임시 사용자(CurrentUser)로 폴백한다.
      'host': AuthStore.instance.user?.hostPayload ?? CurrentUser.hostPayload,
    };
    final response = await c.post(
      Uri.parse('$_baseUrl/api/meetings/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('서버 오류: ${response.statusCode}');
    }
  } finally {
    if (client == null) c.close();
  }
}

/// 모임 목록을 조회한다. [date](단일 날짜) 또는 [dateFrom]/[dateTo](범위) 중
/// 하나를 지정해야 한다(서버 규약). 카테고리·시간대·지역 필터는 앱에서
/// 클라이언트 측으로 적용하므로 여기서는 날짜 범위만 보낸다.
Future<List<Meeting>> fetchMeetings({
  DateTime? date,
  DateTime? dateFrom,
  DateTime? dateTo,
  @visibleForTesting http.Client? client,
}) async {
  final c = client ?? http.Client();
  try {
    final qp = <String, String>{};
    if (date != null) qp['date'] = _fmtDate(date);
    if (dateFrom != null) qp['date_from'] = _fmtDate(dateFrom);
    if (dateTo != null) qp['date_to'] = _fmtDate(dateTo);
    final uri =
        Uri.parse('$_baseUrl/api/meetings/').replace(queryParameters: qp);
    final response = await c.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('서버 오류: ${response.statusCode}');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return [
      for (final e in data) Meeting.fromJson(e as Map<String, dynamic>),
    ];
  } finally {
    if (client == null) c.close();
  }
}

/// 단일 모임 상세를 조회한다.
Future<Meeting> fetchMeetingDetail(
  String id, {
  @visibleForTesting http.Client? client,
}) async {
  final c = client ?? http.Client();
  try {
    final response = await c.get(Uri.parse('$_baseUrl/api/meetings/$id/'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('서버 오류: ${response.statusCode}');
    }
    return Meeting.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  } finally {
    if (client == null) c.close();
  }
}

/// 서버 쿼리용 날짜 포맷 (YYYY-MM-DD).
String _fmtDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
