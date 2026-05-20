import '../models/meeting.dart';
import '../models/meeting_category.dart';

/// 인메모리 목 데이터 저장소.
class MeetingRepository {
  MeetingRepository() {
    _byDay = {};
    for (final m in _seed) {
      _byDay.putIfAbsent(_key(m.startTime), () => []).add(m);
    }
  }

  late final Map<DateTime, List<Meeting>> _byDay;

  static DateTime _key(DateTime d) => DateTime(d.year, d.month, d.day);

  List<Meeting> get allMeetings => List.unmodifiable(_seed);

  /// 해당 날짜 모임을 시작 시각 오름차순으로 반환한다.
  List<Meeting> meetingsOn(DateTime day) {
    final list = [...?_byDay[_key(day)]];
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return List.unmodifiable(list);
  }

  static Meeting _m(
    String id,
    String title,
    MeetingCategory c,
    DateTime start,
    String location,
    String region,
    String locationId,
    int cur,
    int max,
  ) =>
      Meeting(
        id: id,
        title: title,
        category: c,
        startTime: start,
        location: location,
        region: region,
        locationId: locationId,
        currentMembers: cur,
        maxMembers: max,
      );

  static final List<Meeting> _seed = [
    // --- 기존 시드 (변경 금지: 5/16·5/17·5/19) ---
    _m('p1', '아침 코딩 카페', MeetingCategory.cafe,
        DateTime(2026, 5, 12, 9, 0), '신림 스타벅스', '신림', 'seoul-line2', 2, 5),
    _m('p2', '공포 테마 도전', MeetingCategory.escapeRoom,
        DateTime(2026, 5, 14, 20, 0), '강남 비밀의방', '강남', 'seoul-line2', 3, 4),
    _m('t1', '퇴근 후 볼링', MeetingCategory.bowling,
        DateTime(2026, 5, 16, 20, 0), '신림 볼링장', '신림', 'seoul-line2', 4, 6),
    _m('t2', '불금 한잔', MeetingCategory.drink,
        DateTime(2026, 5, 16, 21, 0), '신림 포차거리', '신림', 'seoul-line2', 3, 6),
    _m('a1', '주말 관악산 등반', MeetingCategory.hiking,
        DateTime(2026, 5, 17, 8, 0), '관악산 입구', '신림', 'seoul-line2', 5, 10),
    _m('b1', '방탈출 호러 테마 같이!', MeetingCategory.escapeRoom,
        DateTime(2026, 5, 19, 20, 0), '강남 비밀의방', '강남', 'seoul-line2', 2, 4),
    _m('b2', '코노 1시간', MeetingCategory.karaoke,
        DateTime(2026, 5, 19, 19, 0), '신림 코인노래방', '신림', 'seoul-line2', 2, 6),
    _m('c1', '보드게임 정모', MeetingCategory.boardGame,
        DateTime(2026, 5, 20, 19, 0), '신림 보드카페', '신림', 'seoul-line2', 3, 6),
    _m('c2', '롤 한판', MeetingCategory.lol,
        DateTime(2026, 5, 20, 20, 0), '신림 PC방', '신림', 'seoul-line2', 4, 5),
    _m('c3', '심야 모임', MeetingCategory.etc,
        DateTime(2026, 5, 20, 22, 0), '신림 어딘가', '신림', 'seoul-line2', 2, 4),
    _m('c4', '라떼 한잔', MeetingCategory.cafe,
        DateTime(2026, 5, 20, 15, 0), '신림 카페거리', '신림', 'seoul-line2', 1, 4),
    _m('c5', '소맥 모임', MeetingCategory.drink,
        DateTime(2026, 5, 20, 21, 0), '신림 술집', '신림', 'seoul-line2', 5, 8),
    _m('c6', '노래방 직행', MeetingCategory.karaoke,
        DateTime(2026, 5, 20, 23, 0), '신림 노래타운', '신림', 'seoul-line2', 2, 6),
    _m('d1', '수영 모임', MeetingCategory.swimming,
        DateTime(2026, 5, 21, 7, 0), '강남 수영장', '강남', 'seoul-line2', 3, 5),
    _m('e1', '오후 카페 수다', MeetingCategory.cafe,
        DateTime(2026, 5, 22, 14, 0), '홍대 카페', '홍대', 'seoul-line2', 2, 4),
    _m('f1', '토요 볼링 정모', MeetingCategory.bowling,
        DateTime(2026, 5, 23, 18, 0), '잠실 볼링센터', '잠실', 'seoul-line2', 5, 8),

    // --- 추가 (이번달 후반·다음달, 필터 테스트용) ---
    _m('n1', '서면 코인노래방', MeetingCategory.karaoke,
        DateTime(2026, 5, 21, 19, 0), '부산 서면', '서면', 'busan-line2', 2, 6),
    _m('n2', '광교산 등반', MeetingCategory.hiking,
        DateTime(2026, 5, 21, 6, 30), '수원 광교산', '수원', '경기-수원시', 4, 10),
    _m('n3', '판교 보드게임', MeetingCategory.boardGame,
        DateTime(2026, 5, 22, 20, 0), '성남 판교', '판교', '경기-성남시', 3, 6),
    _m('n4', '부산 PC방 정모', MeetingCategory.lol,
        DateTime(2026, 5, 23, 22, 0), '부산 남포동', '남포', 'busan-line1', 4, 5),
    _m('n5', '제주 오션뷰 카페', MeetingCategory.cafe,
        DateTime(2026, 5, 23, 10, 0), '제주 애월', '애월', '제주-제주시', 2, 4),
    _m('n6', '대구 방탈출', MeetingCategory.escapeRoom,
        DateTime(2026, 5, 25, 13, 0), '대구 동성로', '동성로', 'daegu-line1', 3, 6),
    _m('n7', '강남 포차 한잔', MeetingCategory.drink,
        DateTime(2026, 5, 26, 21, 0), '강남 포차', '강남', 'seoul-line2', 5, 8),
    _m('n8', '인천 새벽 수영', MeetingCategory.swimming,
        DateTime(2026, 5, 27, 8, 0), '인천 수영장', '인천', 'incheon-line1', 2, 6),
    _m('n9', '광화문 보드게임', MeetingCategory.boardGame,
        DateTime(2026, 5, 28, 19, 30), '광화문', '광화문', 'seoul-line5', 3, 6),
    _m('n10', '창원 무학산', MeetingCategory.hiking,
        DateTime(2026, 5, 28, 7, 0), '창원 무학산', '창원', '경남-창원시', 6, 12),
    _m('n11', '신촌 심야 코노', MeetingCategory.karaoke,
        DateTime(2026, 5, 29, 23, 0), '신촌', '신촌', 'seoul-line2', 4, 8),
    _m('n12', '청주 디저트 카페', MeetingCategory.cafe,
        DateTime(2026, 5, 30, 15, 0), '청주', '청주', '충북-청주시', 2, 5),
    _m('n13', '광주 롤 모임', MeetingCategory.lol,
        DateTime(2026, 5, 31, 20, 0), '광주 충장로', '충장로', 'gwangju-line1', 3, 5),
    _m('n14', '압구정 방탈출', MeetingCategory.escapeRoom,
        DateTime(2026, 6, 1, 14, 0), '압구정', '압구정', 'seoul-line3', 2, 6),
    _m('n15', '수원 점심 볼링', MeetingCategory.bowling,
        DateTime(2026, 6, 2, 12, 30), '수원역', '수원', '경기-수원시', 4, 8),
    _m('n16', '광안리 술 한잔', MeetingCategory.drink,
        DateTime(2026, 6, 3, 20, 0), '부산 광안리', '광안리', 'busan-line2', 4, 8),
    _m('n17', '춘천 삼악산', MeetingCategory.hiking,
        DateTime(2026, 6, 5, 6, 30), '춘천 삼악산', '춘천', '강원-춘천시', 5, 10),
    _m('n18', '대전 주말 볼링', MeetingCategory.bowling,
        DateTime(2026, 6, 7, 17, 0), '대전 둔산', '둔산', 'daejeon-line1', 4, 8),
    _m('n19', '여의도 브런치 카페', MeetingCategory.cafe,
        DateTime(2026, 6, 10, 11, 0), '여의도', '여의도', 'seoul-line9', 2, 4),
    _m('n20', '일산 보드게임', MeetingCategory.boardGame,
        DateTime(2026, 6, 12, 19, 0), '고양 일산', '일산', '경기-고양시', 3, 6),
    _m('n21', '주말 수영 클래스', MeetingCategory.swimming,
        DateTime(2026, 6, 14, 9, 0), '강남 수영장', '강남', 'seoul-line7', 2, 6),
    _m('n22', '대구 밤 코노', MeetingCategory.karaoke,
        DateTime(2026, 6, 16, 22, 0), '대구 반월당', '반월당', 'daegu-line2', 3, 8),
    _m('n23', '인천 번개 모임', MeetingCategory.etc,
        DateTime(2026, 6, 20, 18, 0), '인천 송도', '송도', 'incheon-line2', 2, 4),
    _m('n24', '강남 심야 롤', MeetingCategory.lol,
        DateTime(2026, 6, 25, 21, 0), '강남 PC방', '강남', 'seoul-line2', 5, 5),
    _m('n25', '서귀포 한잔', MeetingCategory.drink,
        DateTime(2026, 6, 28, 20, 30), '서귀포', '서귀포', '제주-서귀포시', 3, 6),
  ];
}
