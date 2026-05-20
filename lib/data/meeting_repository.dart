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

  List<Meeting> meetingsOn(DateTime day) =>
      List.unmodifiable(_byDay[_key(day)] ?? const []);

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

  // 시드의 region(신림/강남/홍대/잠실)은 모두 서울 2호선 권역 → locationId 'seoul-line2'.
  static final List<Meeting> _seed = [
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
  ];
}
