import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../features/chat/chat_message.dart';

/// 채팅 REST API. `meeting_api.dart`의 규약을 따른다:
/// 최상위 함수 + `@visibleForTesting http.Client?` 주입 + `utf8.decode(bodyBytes)`.
///
/// 인증 전까지 현재 사용자는 `X-Participant-Id` 헤더로 식별한다.
/// TODO(auth): 로그인 토큰 기반으로 교체한다.
const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

/// 채팅 히스토리 조회. `GET /api/meetings/{meetingId}/messages/`
/// (오래된→최신 순). 각 메시지 `unread_count` 포함.
Future<List<ChatMessage>> fetchMessages({
  required String meetingId,
  required int participantId,
  required String myNickname,
  @visibleForTesting http.Client? client,
}) async {
  final c = client ?? http.Client();
  try {
    final response = await c.get(
      Uri.parse('$_baseUrl/api/meetings/$meetingId/messages/'),
      headers: {'X-Participant-Id': '$participantId'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('서버 오류: ${response.statusCode}');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return [
      for (final e in data)
        ChatMessage.fromJson(e as Map<String, dynamic>, myNickname: myNickname),
    ];
  } finally {
    if (client == null) c.close();
  }
}

/// 메시지 전송. `POST /api/meetings/{meetingId}/messages/` → 생성된 메시지 1건.
Future<ChatMessage> sendMessage({
  required String meetingId,
  required int participantId,
  required String myNickname,
  required String text,
  @visibleForTesting http.Client? client,
}) async {
  final c = client ?? http.Client();
  try {
    final response = await c.post(
      Uri.parse('$_baseUrl/api/meetings/$meetingId/messages/'),
      headers: {
        'Content-Type': 'application/json',
        'X-Participant-Id': '$participantId',
      },
      body: jsonEncode({'text': text}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('서버 오류: ${response.statusCode}');
    }
    return ChatMessage.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      myNickname: myNickname,
    );
  } finally {
    if (client == null) c.close();
  }
}

/// 읽음 위치 갱신. `PATCH /api/meetings/{meetingId}/read/`
/// → 영향받은 메시지들의 안읽음 수 맵 `{messageId: count}`(부분 갱신).
Future<Map<String, int>> markRead({
  required String meetingId,
  required int participantId,
  required String lastReadMessageId,
  @visibleForTesting http.Client? client,
}) async {
  final c = client ?? http.Client();
  try {
    final response = await c.patch(
      Uri.parse('$_baseUrl/api/meetings/$meetingId/read/'),
      headers: {
        'Content-Type': 'application/json',
        'X-Participant-Id': '$participantId',
      },
      body: jsonEncode({'last_read_message_id': int.parse(lastReadMessageId)}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('서버 오류: ${response.statusCode}');
    }
    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final unread = (body['unread'] as Map<String, dynamic>?) ?? {};
    return unread.map((k, v) => MapEntry(k, (v as num).toInt()));
  } finally {
    if (client == null) c.close();
  }
}
