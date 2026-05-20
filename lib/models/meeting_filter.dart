import 'meeting.dart';
import 'meeting_category.dart';
import 'time_band.dart';

/// 모임 필터 선택값 + 매칭 로직(순수).
class MeetingFilter {
  const MeetingFilter({
    this.categories = const {},
    this.locationIds = const {},
    this.timeBands = const {},
    this.customCategories = const {},
  });

  const MeetingFilter.empty()
      : categories = const {},
        locationIds = const {},
        timeBands = const {},
        customCategories = const {};

  final Set<MeetingCategory> categories;
  final Set<String> locationIds;
  final Set<TimeBand> timeBands;

  /// 직접 입력한 카테고리. 저장·표시되나 목 데이터 매칭엔 미적용.
  final Set<String> customCategories;

  bool get isEmpty =>
      categories.isEmpty &&
      locationIds.isEmpty &&
      timeBands.isEmpty &&
      customCategories.isEmpty;

  int get activeCount =>
      categories.length +
      locationIds.length +
      timeBands.length +
      customCategories.length;

  /// 빈 섹션은 제약 없음. 채워진 섹션은 모두(AND) 만족해야 통과.
  bool matches(Meeting m) {
    if (categories.isNotEmpty && !categories.contains(m.category)) {
      return false;
    }
    if (locationIds.isNotEmpty && !locationIds.contains(m.locationId)) {
      return false;
    }
    if (timeBands.isNotEmpty &&
        !timeBands.any((b) => b.containsHour(m.startTime.hour))) {
      return false;
    }
    return true;
  }
}
