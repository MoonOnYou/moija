import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/auth_user.dart';

/// 로그인 세션(JWT 토큰 + 사용자)을 보관하고 SharedPreferences에 영속한다.
///
/// 앱 전역에서 `AuthStore.instance`로 접근한다. 로그인 상태 변화는
/// [userNotifier]를 구독해 감지한다(앱 관례: ValueNotifier).
/// TODO(auth): access 토큰 만료 시 refresh로 갱신하는 로직 추가.
class AuthStore {
  AuthStore._();
  static final AuthStore instance = AuthStore._();

  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kUser = 'auth_user';

  /// 현재 로그인 사용자(없으면 null). 로그인/로그아웃 시 값이 바뀐다.
  final ValueNotifier<AuthUser?> userNotifier = ValueNotifier<AuthUser?>(null);

  String? _access;
  String? _refresh;

  String? get accessToken => _access;
  String? get refreshToken => _refresh;
  AuthUser? get user => userNotifier.value;
  bool get isLoggedIn => _access != null && userNotifier.value != null;

  /// 앱 시작 시 저장된 세션을 복원한다.
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _access = p.getString(_kAccess);
    _refresh = p.getString(_kRefresh);
    final userJson = p.getString(_kUser);
    if (userJson != null) {
      try {
        userNotifier.value =
            AuthUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {
        // 저장 포맷이 깨졌으면 로그아웃 상태로 둔다.
      }
    }
  }

  /// 로그인/회원가입 성공 시 세션을 저장한다.
  Future<void> save({
    required String access,
    required String refresh,
    required AuthUser user,
  }) async {
    _access = access;
    _refresh = refresh;
    userNotifier.value = user;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAccess, access);
    await p.setString(_kRefresh, refresh);
    await p.setString(_kUser, jsonEncode(user.toJson()));
  }

  /// 프로필만 갱신(닉네임/자기소개 수정 등). 토큰은 유지.
  Future<void> updateUser(AuthUser user) async {
    userNotifier.value = user;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUser, jsonEncode(user.toJson()));
  }

  /// 로그아웃 — 로컬 세션을 모두 지운다.
  Future<void> clear() async {
    _access = null;
    _refresh = null;
    userNotifier.value = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccess);
    await p.remove(_kRefresh);
    await p.remove(_kUser);
  }
}
