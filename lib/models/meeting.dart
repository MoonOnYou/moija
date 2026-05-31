import 'package:flutter/widgets.dart';
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
    this.customIcon,
    this.description = '',
    this.nearestStation = '',
    this.cost = const MeetingCost(CostType.split),
    this.joinMethod = JoinMethod.approval,
  });

  /// 서버 응답(JSON)을 Meeting으로 변환한다. 알 수 없는 enum 값은 안전한
  /// 기본값으로 대체한다(category→etc, joinMethod→approval, cost→split).
  factory Meeting.fromJson(Map<String, dynamic> json) {
    MeetingCategory parseCategory(Object? name) {
      for (final c in MeetingCategory.values) {
        if (c.name == name) return c;
      }
      return MeetingCategory.etc;
    }

    JoinMethod parseJoin(Object? name) {
      for (final j in JoinMethod.values) {
        if (j.name == name) return j;
      }
      return JoinMethod.approval;
    }

    CostType parseCost(Object? name) {
      for (final t in CostType.values) {
        if (t.name == name) return t;
      }
      return CostType.split;
    }

    final customText = (json['cost_custom_text'] as String?) ?? '';
    return Meeting(
      id: json['id'].toString(),
      title: (json['title'] as String?) ?? '',
      category: parseCategory(json['category']),
      customCategory: (json['custom_category'] as String?) ?? '',
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      location: (json['location'] as String?) ?? '',
      region: (json['region'] as String?) ?? '',
      locationId: (json['location_id'] as String?) ?? '',
      currentMembers: (json['current_members'] as num?)?.toInt() ?? 0,
      maxMembers: (json['max_members'] as num?)?.toInt() ?? 0,
      description: (json['description'] as String?) ?? '',
      nearestStation: (json['nearest_station'] as String?) ?? '',
      cost: MeetingCost(
        parseCost(json['cost_type']),
        amountWon: (json['cost_amount_won'] as num?)?.toInt(),
        customText: customText.isEmpty ? null : customText,
      ),
      joinMethod: parseJoin(json['join_method']),
    );
  }

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

  /// 전체보기에서 고른 카테고리처럼 enum 아이콘으로 매핑되지 않는 경우의
  /// 대체 아이콘. null이면 [category]의 기본 아이콘을 쓴다.
  final IconData? customIcon;

  /// 상세 화면 정보(저장소가 채움).
  final String description;
  final String nearestStation;
  final MeetingCost cost;
  final JoinMethod joinMethod;

  /// 칩·달력에 표시할 카테고리 이름. 직접 입력값이 있으면 그걸 우선한다.
  String get categoryLabel =>
      customCategory.isNotEmpty ? customCategory : category.label;

  /// 리스트·상세에 표시할 아이콘. 직접 지정한 아이콘이 있으면 그걸, 없으면
  /// 카테고리 기본 아이콘을 쓴다.
  IconData get icon => customIcon ?? category.icon;

  /// 리스트·상세에 공통으로 쓰는 장소 표시. 인근역 정보가 있고 장소와 다르면
  /// "인근역 · 장소" 형태로, 아니면 장소만 보여준다.
  String get placeLabel {
    if (nearestStation.isEmpty || nearestStation == location) return location;
    return '$nearestStation · $location';
  }

  int get spotsLeft => maxMembers - currentMembers;
  bool get isFull => spotsLeft <= 0;
}
