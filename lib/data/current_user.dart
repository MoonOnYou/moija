import '../models/member.dart';

/// 로그인/인증 도입 전까지 사용하는 임시 현재 사용자(목).
///
/// 모임 생성 시 서버가 필수로 요구하는 `host` 프로필(닉네임·출생연도·성별 등)을
/// 채우기 위한 값이다. 값은 프로필 화면의 mock 프로필과 맞춰 두었다.
///
/// TODO(auth): 인증/프로필 API 연동 시 실제 로그인 사용자로 교체한다.
class CurrentUser {
  const CurrentUser._();

  static const String nickname = '나';
  static const int birthYear = 1998;
  static const Gender gender = Gender.female;
  static const double mannerScore = 4.7;
  static const int totalActivities = 12;
  static const String intro = '함께 한잔 좋아하고, 처음 만나는 사람 환영해요 :)';

  /// 모임 생성 API(`POST /api/meetings/`)의 `host` 페이로드.
  /// 서버 `HostInputSerializer` 필드명(snake_case)에 맞춘다.
  static Map<String, dynamic> get hostPayload => {
        'nickname': nickname,
        'birth_year': birthYear,
        'gender': gender.name,
        'manner_score': mannerScore,
        'total_activities': totalActivities,
        'intro': intro,
      };
}
