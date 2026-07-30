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
    this.isHost = false,
  });

  final String nickname;
  final int birthYear;
  final Gender gender;
  final double mannerScore; // 0~5
  final int totalActivities;
  final int timesMetWithMe;
  final String intro;

  /// 방장 여부. 서버 참가자 목록은 방장이 앞에 오도록 정렬된다.
  final bool isHost;

  /// 서버 참가자 JSON을 Member로 변환한다.
  /// (서버 ParticipantSerializer: nickname, birth_year, gender, manner_score,
  ///  total_activities, intro, is_host)
  factory Member.fromJson(Map<String, dynamic> json) => Member(
        nickname: (json['nickname'] as String?) ?? '',
        birthYear: (json['birth_year'] as num?)?.toInt() ?? 0,
        gender: json['gender'] == 'male' ? Gender.male : Gender.female,
        mannerScore: (json['manner_score'] as num?)?.toDouble() ?? 0,
        totalActivities: (json['total_activities'] as num?)?.toInt() ?? 0,
        timesMetWithMe: 0, // 서버 미제공(상대와의 관계 값)
        intro: (json['intro'] as String?) ?? '',
        isHost: (json['is_host'] as bool?) ?? false,
      );
}
