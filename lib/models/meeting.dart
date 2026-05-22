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
    this.customCategory = '',
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

  /// 직접 입력한 카테고리 이름. 비어 있지 않으면 [category] 라벨 대신 표시한다.
  /// 이때 [category]는 보통 [MeetingCategory.etc]로 저장된다.
  final String customCategory;

  /// 상세 화면 정보(저장소가 채움).
  final String description;
  final String nearestStation;
  final MeetingCost cost;
  final JoinMethod joinMethod;

  /// 칩·달력에 표시할 카테고리 이름. 직접 입력값이 있으면 그걸 우선한다.
  String get categoryLabel =>
      customCategory.isNotEmpty ? customCategory : category.label;

  /// 리스트·상세에 공통으로 쓰는 장소 표시. 인근역 정보가 있고 장소와 다르면
  /// "인근역 · 장소" 형태로, 아니면 장소만 보여준다.
  String get placeLabel {
    if (nearestStation.isEmpty || nearestStation == location) return location;
    return '$nearestStation · $location';
  }

  int get spotsLeft => maxMembers - currentMembers;
  bool get isFull => spotsLeft <= 0;
}
