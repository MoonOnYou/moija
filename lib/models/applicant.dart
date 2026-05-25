import 'member.dart';

/// 승인제 모임의 신청자. 멤버 프로필에 "방장에게 한마디"(선택)가 붙는다.
class Applicant {
  const Applicant({required this.member, this.message});

  final Member member;
  final String? message;
}
