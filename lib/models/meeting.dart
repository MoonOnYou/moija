import 'join_method.dart';
import 'meeting_category.dart';
import 'meeting_cost.dart';

class Meeting {
  const Meeting({
    required this.id,
    required this.title,
    required this.category,
    required this.startTime,
    required this.location,
    required this.region,
    required this.locationId,
    required this.currentMembers,
    required this.maxMembers,
    this.description = '',
    this.nearestStation = '',
    this.cost = const MeetingCost(CostType.split),
    this.joinMethod = JoinMethod.approval,
  });

  final String id;
  final String title;
  final MeetingCategory category;
  final DateTime startTime;
  final String location;

  /// 달력 칩에 쓰는 짧은 지역명(예: "신림").
  final String region;

  /// 장소 카탈로그 노드 id(예: "seoul-line2"). 장소 필터에 사용.
  final String locationId;

  final int currentMembers;
  final int maxMembers;

  /// 상세 화면 정보(저장소가 채움).
  final String description;
  final String nearestStation;
  final MeetingCost cost;
  final JoinMethod joinMethod;

  int get spotsLeft => maxMembers - currentMembers;
  bool get isFull => spotsLeft <= 0;
}
