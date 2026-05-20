/// 성별.
enum Gender {
  male('남'),
  female('여');

  const Gender(this.label);
  final String label;
}

/// 모임 참가자 프로필.
class Member {
  const Member({
    required this.nickname,
    required this.birthYear,
    required this.gender,
    required this.mannerScore,
    required this.totalActivities,
    required this.timesMetWithMe,
    required this.intro,
  });

  final String nickname;
  final int birthYear;
  final Gender gender;
  final double mannerScore; // 0~5
  final int totalActivities;
  final int timesMetWithMe;
  final String intro;
}
