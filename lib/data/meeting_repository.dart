import '../models/meeting.dart';
import '../models/meeting_category.dart';

/// 인메모리 목 데이터 저장소. 후일 백엔드 구현으로 교체 가능하도록
/// 단순한 조회 인터페이스만 노출한다.
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

  static final List<Meeting> _seed = [
    Meeting(
      id: 'm1',
      title: '주말 볼링 한 게임',
      category: MeetingCategory.bowling,
      startTime: DateTime(2026, 5, 10, 19, 0),
      location: '강남 볼링장',
      currentMembers: 3,
      maxMembers: 6,
    ),
    Meeting(
      id: 'm2',
      title: '방탈출 입문 모임',
      category: MeetingCategory.escapeRoom,
      startTime: DateTime(2026, 5, 14, 19, 30),
      location: '홍대 키이스케이프',
      currentMembers: 2,
      maxMembers: 4,
    ),
    Meeting(
      id: 'm3',
      title: '퇴근 후 볼링',
      category: MeetingCategory.bowling,
      startTime: DateTime(2026, 5, 16, 20, 0),
      location: '강남 볼링장',
      currentMembers: 4,
      maxMembers: 6,
    ),
    Meeting(
      id: 'm4',
      title: '방탈출 호러 테마 같이!',
      category: MeetingCategory.escapeRoom,
      startTime: DateTime(2026, 5, 19, 20, 0),
      location: '강남 비밀의방',
      currentMembers: 2,
      maxMembers: 4,
    ),
    Meeting(
      id: 'm5',
      title: '토요일 볼링 정모',
      category: MeetingCategory.bowling,
      startTime: DateTime(2026, 5, 23, 18, 0),
      location: '잠실 볼링센터',
      currentMembers: 5,
      maxMembers: 8,
    ),
    Meeting(
      id: 'm6',
      title: 'SF 테마 방탈출',
      category: MeetingCategory.escapeRoom,
      startTime: DateTime(2026, 5, 28, 20, 30),
      location: '강남 비밀의방',
      currentMembers: 1,
      maxMembers: 4,
    ),
  ];
}
