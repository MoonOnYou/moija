import '../../models/member.dart';

/// 가입 플로우 전 단계에서 공유되는 사용자 입력 묶음.
/// 각 화면이 Navigator로 push되며 같은 인스턴스를 전달받아 채워 나간다.
class SignupSession {
  SignupSession();

  // 약관
  bool agreedService = false;
  bool agreedPrivacy = false;
  bool agreedLocation = false;
  bool agreedAge = false; // 만 14세 이상
  bool agreedMarketing = false; // 선택

  // 전화번호 · 인증
  String phone = ''; // 숫자만 (예: 01012345678)

  // 로그인 비밀번호 (영문+숫자 8자 이상)
  String password = '';

  // 프로필
  String nickname = '';
  Gender? gender;
  int? birthYear;
  String intro = ''; // 자기소개 (선택)

  // 관심사 / 동네
  final Set<String> interestCategories = <String>{};
  final Set<String> interestLocations = <String>{};

  bool get allRequiredAgreed =>
      agreedService && agreedPrivacy && agreedLocation && agreedAge;
}
