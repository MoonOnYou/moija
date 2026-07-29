import 'member.dart';

/// 로그인/회원가입 응답의 사용자 프로필. 서버 `apps.accounts` User와 정합.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.phone,
    required this.nickname,
    required this.birthYear,
    required this.gender,
    required this.mannerScore,
    required this.totalActivities,
    required this.intro,
    this.interestCategories = const [],
    this.interestLocations = const [],
  });

  final int id;
  final String phone;
  final String nickname;
  final int birthYear;
  final Gender gender;
  final double mannerScore;
  final int totalActivities;
  final String intro;
  final List<String> interestCategories;
  final List<String> interestLocations;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final rawGender = json['gender'] as String?;
    return AuthUser(
      id: json['id'] as int,
      phone: (json['phone'] ?? '') as String,
      nickname: (json['nickname'] ?? '') as String,
      birthYear: (json['birth_year'] ?? 0) as int,
      gender: rawGender == 'male' ? Gender.male : Gender.female,
      mannerScore: (json['manner_score'] as num?)?.toDouble() ?? 0,
      totalActivities: (json['total_activities'] ?? 0) as int,
      intro: (json['intro'] ?? '') as String,
      interestCategories: _strList(json['interest_categories']),
      interestLocations: _strList(json['interest_locations']),
    );
  }

  /// 로컬 영속(SharedPreferences)용 직렬화.
  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'nickname': nickname,
        'birth_year': birthYear,
        'gender': gender.name,
        'manner_score': mannerScore,
        'total_activities': totalActivities,
        'intro': intro,
        'interest_categories': interestCategories,
        'interest_locations': interestLocations,
      };

  AuthUser copyWith({String? nickname, String? intro}) => AuthUser(
        id: id,
        phone: phone,
        nickname: nickname ?? this.nickname,
        birthYear: birthYear,
        gender: gender,
        mannerScore: mannerScore,
        totalActivities: totalActivities,
        intro: intro ?? this.intro,
        interestCategories: interestCategories,
        interestLocations: interestLocations,
      );

  static List<String> _strList(dynamic v) =>
      v is List ? v.map((e) => e.toString()).toList() : const [];
}
