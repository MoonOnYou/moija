import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../features/signup/signup_session.dart';
import '../../models/auth_user.dart';

/// 인증 API. `meeting_api.dart` 규약(최상위 함수 + `http.Client?` 주입)을 따른다.
const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

/// 서버가 반환한 사용자 친화적 에러 메시지(`detail`)를 담는 예외.
class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 로그인/회원가입 결과(토큰 + 사용자).
class AuthResult {
  const AuthResult({required this.access, required this.refresh, required this.user});
  final String access;
  final String refresh;
  final AuthUser user;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        access: json['access'] as String,
        refresh: json['refresh'] as String,
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

Map<String, dynamic> _decode(http.Response r) =>
    jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;

/// 2xx가 아니면 서버 `detail`을 담아 AuthException을 던진다.
void _ensureOk(http.Response r) {
  if (r.statusCode >= 200 && r.statusCode < 300) return;
  String msg = '요청을 처리하지 못했습니다. (${r.statusCode})';
  try {
    final body = _decode(r);
    if (body['detail'] is String) msg = body['detail'] as String;
  } catch (_) {}
  throw AuthException(msg);
}

/// 번호 사용 가능 여부. `reason`은 `registered`(이미 가입) / `cooldown`(탈퇴 쿨다운) / null.
class PhoneAvailability {
  const PhoneAvailability({
    required this.available,
    required this.detail,
    this.reason,
  });

  final bool available;
  final String detail;
  final String? reason;

  /// 이미 가입된 번호 — 로그인 안내를 함께 띄울 수 있다.
  bool get isRegistered => reason == 'registered';

  factory PhoneAvailability.fromJson(Map<String, dynamic> json) =>
      PhoneAvailability(
        available: json['available'] == true,
        detail: json['detail'] as String? ?? '',
        reason: json['reason'] as String?,
      );
}

/// 가입 가능한 번호인지 확인. 전화번호 입력 직후 호출해 중복 가입을 즉시 알린다.
Future<PhoneAvailability> checkPhone(
  String phone, {
  @visibleForTesting http.Client? client,
}) async {
  final c = client ?? http.Client();
  try {
    final r = await c.post(
      Uri.parse('$_baseUrl/api/auth/check-phone/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    _ensureOk(r);
    return PhoneAvailability.fromJson(_decode(r));
  } finally {
    if (client == null) c.close();
  }
}

/// OTP 발송. 응답에는 `detail`과 (DEBUG 서버 한정) `dev_code`가 포함된다.
Future<Map<String, dynamic>> sendOtp(
  String phone, {
  @visibleForTesting http.Client? client,
}) async {
  final c = client ?? http.Client();
  try {
    final r = await c.post(
      Uri.parse('$_baseUrl/api/auth/send-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    _ensureOk(r);
    return _decode(r);
  } finally {
    if (client == null) c.close();
  }
}

/// OTP 검증 → verification_token 반환(register/withdraw에 재사용).
Future<String> verifyOtp(
  String phone,
  String code, {
  String purpose = 'signup',
  @visibleForTesting http.Client? client,
}) async {
  final c = client ?? http.Client();
  try {
    final r = await c.post(
      Uri.parse('$_baseUrl/api/auth/verify-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'code': code, 'purpose': purpose}),
    );
    _ensureOk(r);
    return _decode(r)['verification_token'] as String;
  } finally {
    if (client == null) c.close();
  }
}

/// 회원가입 → 토큰 + 사용자.
Future<AuthResult> register(
  SignupSession s,
  String verificationToken, {
  @visibleForTesting http.Client? client,
}) async {
  final c = client ?? http.Client();
  try {
    final body = {
      'phone': s.phone,
      'password': s.password,
      'nickname': s.nickname,
      'gender': s.gender!.name,
      'birth_year': s.birthYear,
      'intro': s.intro,
      'interest_categories': s.interestCategories.toList(),
      'interest_locations': s.interestLocations.toList(),
      'agreed_service': s.agreedService,
      'agreed_privacy': s.agreedPrivacy,
      'agreed_location': s.agreedLocation,
      'agreed_age': s.agreedAge,
      'agreed_marketing': s.agreedMarketing,
      'verification_token': verificationToken,
    };
    final r = await c.post(
      Uri.parse('$_baseUrl/api/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _ensureOk(r);
    return AuthResult.fromJson(_decode(r));
  } finally {
    if (client == null) c.close();
  }
}

/// 로그인 → 토큰 + 사용자.
Future<AuthResult> login(
  String phone,
  String password, {
  @visibleForTesting http.Client? client,
}) async {
  final c = client ?? http.Client();
  try {
    final r = await c.post(
      Uri.parse('$_baseUrl/api/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    _ensureOk(r);
    return AuthResult.fromJson(_decode(r));
  } finally {
    if (client == null) c.close();
  }
}

/// 로그아웃 → refresh 토큰 블랙리스트. 실패해도 로컬 세션은 정리 대상이므로
/// 예외를 삼킨다(best-effort).
Future<void> logout(
  String refresh, {
  @visibleForTesting http.Client? client,
}) async {
  final c = client ?? http.Client();
  try {
    await c.post(
      Uri.parse('$_baseUrl/api/auth/logout/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );
  } catch (_) {
    // 네트워크 오류 등은 무시 — 로컬 토큰은 호출측에서 지운다.
  } finally {
    if (client == null) c.close();
  }
}
