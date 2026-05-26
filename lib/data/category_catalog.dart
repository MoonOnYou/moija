import '../models/meeting_category.dart';

/// 전체보기 화면에 노출할 카테고리 그룹·서브 라벨.
/// 라벨이 [MeetingCategory] enum에 매핑되면 그 enum으로, 아니면 [MeetingCategory.etc] +
/// customCategory에 라벨 원문을 저장한다.
class CategoryCatalog {
  const CategoryCatalog._();

  /// 빠른 선택 칩(필터·모임 만들기 메인). "전체보기"는 호출자 측에서 별도로 처리한다.
  static const List<MeetingCategory> mainShortcuts = [
    MeetingCategory.restaurant,
    MeetingCategory.drink,
    MeetingCategory.boardGame,
    MeetingCategory.escapeRoom,
    MeetingCategory.karaoke,
    MeetingCategory.billiards,
    MeetingCategory.bowling,
    MeetingCategory.climbing,
    MeetingCategory.hiking,
    MeetingCategory.running,
    MeetingCategory.movie,
  ];

  /// 큰 그룹 → 서브 라벨 목록. 표 그대로.
  static const List<({String title, List<String> items})> groups = [
    (
      title: '운동·스포츠',
      items: [
        '배드민턴', '테니스', '탁구', '스쿼시',
        '볼링', '풋살', '농구', '당구',
        '클라이밍', '등산', '러닝', '자전거',
        '수영', '서핑', '요가', '필라테스',
        '복싱', '주짓수', '헬스', '춤', '골프',
      ],
    ),
    (
      title: '맛집·술·카페',
      items: ['맛집', '카페', '술한잔', '비건'],
    ),
    (
      title: '자기개발·스터디',
      items: [
        '자기개발', '모닝 루틴', '어학', '독서모임',
        '글쓰기·블로그', '재테크·부업', '컨퍼런스·세미나',
      ],
    ),
    (
      title: '문화·예술',
      items: [
        '전시', '공연', '영화', '콘서트·페스티벌',
        '사진 출사', '드로잉', '책방 투어', 'LP·재즈바',
      ],
    ),
    (
      title: '놀이·게임',
      items: [
        '보드게임', '방탈출', '노래방', '다트',
        'VR·오락실', '마작·포커', 'PC방·이스포츠', '닌텐도 스위치',
      ],
    ),
    (
      title: '야외·체험',
      items: [
        '캠핑·차박·글램핑', '피크닉·한강', '동네 산책·도시 탐방',
        '페스티벌 동행', '워터파크·놀이공원', '플리마켓', '봉사활동',
      ],
    ),
    (
      title: '만들기·공방',
      items: [
        '도자기·공예', '베이킹·쿠킹', '향초·향수·디퓨저',
        '가죽·금속 공예', '칵테일·바리스타 클래스',
      ],
    ),
    (
      title: '기타',
      items: ['기타'],
    ),
  ];

  /// 라벨 → enum. 일치하는 enum이 있으면 그 값을, 없으면 [MeetingCategory.etc].
  /// 호출자는 매핑 결과 enum과 별개로 customCategory에 라벨 원문을 저장하면 된다.
  static MeetingCategory categoryFor(String label) {
    for (final c in MeetingCategory.values) {
      if (c.label == label) return c;
    }
    // 표에는 있지만 enum이 따로 없는 별칭 — 가까운 enum으로 폴백.
    switch (label) {
      case '비건':
        return MeetingCategory.restaurant;
      case 'PC방·이스포츠':
        return MeetingCategory.lol;
      default:
        return MeetingCategory.etc;
    }
  }
}
