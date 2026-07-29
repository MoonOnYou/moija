import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/auth_user.dart';
import '../auth/auth_store.dart';

/// `/api/me/*` — JWT 인증이 필요한 사용자 API.
/// `Authorization: Bearer <access>` 헤더를 AuthStore에서 주입한다.
const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

Map<String, String> _authHeaders() {
  final token = AuthStore.instance.accessToken;
  return {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

/// 내 프로필 조회. 서버 최신값(매너점수·활동수 등)을 반영할 때 사용.
Future<AuthUser> fetchMe({@visibleForTesting http.Client? client}) async {
  final c = client ?? http.Client();
  try {
    final r = await c.get(
      Uri.parse('$_baseUrl/api/me/'),
      headers: _authHeaders(),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('프로필 조회 실패: ${r.statusCode}');
    }
    return AuthUser.fromJson(
        jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>);
  } finally {
    if (client == null) c.close();
  }
}

/// 닉네임·자기소개 수정(부분). 갱신된 프로필을 반환한다.
Future<AuthUser> updateProfile({
  String? nickname,
  String? intro,
  @visibleForTesting http.Client? client,
}) async {
  final c = client ?? http.Client();
  try {
    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (intro != null) body['intro'] = intro;
    final r = await c.patch(
      Uri.parse('$_baseUrl/api/me/'),
      headers: _authHeaders(),
      body: jsonEncode(body),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('프로필 수정 실패: ${r.statusCode}');
    }
    return AuthUser.fromJson(
        jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>);
  } finally {
    if (client == null) c.close();
  }
}
