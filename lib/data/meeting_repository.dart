import 'package:flutter/foundation.dart';
import '../features/chat/chat_message.dart';
import '../models/join_method.dart';
import '../models/meeting.dart';
import '../models/meeting_category.dart';
import '../models/meeting_cost.dart';
import '../models/member.dart';

/// 인메모리 목 데이터 저장소.
class MeetingRepository {
  /// [baseTime] 기준으로 "내가 참가/방장/대기 중인" 모임을 상대 시각으로 시드한다.
  /// 테스트는 baseTime을 고정해 결정성을 확보한다.
  MeetingRepository({DateTime? baseTime, bool browseSeed = true}) {
    final now = baseTime ?? DateTime.now();
    final my = _buildMySeed(now);
    _myJoinedIds = my.joinedIds;
    _myHostedIds = my.hostedIds;
    _myPendingIds = my.pendingIds;

    // _seed 는 홈 달력/목록에 노출되는 하드코딩 mock(브라우즈 시드)이다.
    // 서버 연동 앱은 browseSeed:false 로 끄고 API 데이터만 보여준다.
    final browse = browseSeed ? _seed : const <Meeting>[];
    // 내 모임 시드는 채팅/내모임용으로 allMeetings 에만 두고, 날짜 인덱스
    // (_byDay → meetingsOn)에는 넣지 않는다. 그래야 홈 달력/목록에는
    // 하드코딩된 내 모임이 섞여 보이지 않고 서버 데이터만 나온다.
    _all = [...browse, ...my.meetings];
    _byDay = {};
    for (final m in browse) {
      _byDay.putIfAbsent(_key(m.startTime), () => []).add(m);
    }
  }

  /// 테스트 격리용 생성자. 시드를 만들지 않고, 주어진 데이터만 보유한다.
  @visibleForTesting
  MeetingRepository.test({
    List<Meeting> meetings = const [],
    Set<String> joined = const {},
    Set<String> hosted = const {},
    Set<String> pending = const {},
  }) {
    _all = [...meetings];
    _byDay = {};
    for (final m in _all) {
      _byDay.putIfAbsent(_key(m.startTime), () => []).add(m);
    }
    _myJoinedIds = {...joined};
    _myHostedIds = {...hosted};
    _myPendingIds = {...pending};
  }

  late final List<Meeting> _all;
  late final Map<DateTime, List<Meeting>> _byDay;
  late final Set<String> _myJoinedIds;
  late final Set<String> _myHostedIds;
  late final Set<String> _myPendingIds;

  static DateTime _key(DateTime d) => DateTime(d.year, d.month, d.day);

  List<Meeting> get allMeetings => List.unmodifiable(_all);

  /// 내가 참가(방장 포함)한 모임 id. 신청 대기는 포함하지 않는다.
  Set<String> get myJoinedIds => Set.unmodifiable(_myJoinedIds);

  /// 내가 방장인 모임 id.
  Set<String> get myHostedIds => Set.unmodifiable(_myHostedIds);

  /// 내가 신청해 대기 중인 모임 id.
  Set<String> get myPendingIds => Set.unmodifiable(_myPendingIds);

  /// 신청 대기를 취소한다(테스트·UI에서 호출). 노출 목록에서 빠진다.
  void cancelPending(String meetingId) {
    _myPendingIds.remove(meetingId);
  }

  /// 내 모임에서 나간다. 방장 권한도 같이 사라진다(mock 단순화).
  void leave(String meetingId) {
    _myJoinedIds.remove(meetingId);
    _myHostedIds.remove(meetingId);
    _sentMessages.remove(meetingId);
  }

  /// mock 채팅방에서 내가 보낸 메시지. 화면 State가 아니라 저장소가 들고 있어야
  /// 채팅방을 나갔다 와도 남고, 내모임 미리보기에도 같은 내용이 보인다.
  /// TODO(chat): 채팅 API 연동 시 서버 히스토리로 대체한다.
  final Map<String, List<ChatMessage>> _sentMessages = {};

  List<ChatMessage> sentMessagesOf(String meetingId) =>
      List.unmodifiable(_sentMessages[meetingId] ?? const <ChatMessage>[]);

  void addSentMessage(String meetingId, ChatMessage message) {
    _sentMessages.putIfAbsent(meetingId, () => []).add(message);
  }

  /// 방장 자리를 다른 멤버에게 넘긴다. 나는 일반 참가자로 남는다.
  void delegateHost(String meetingId) {
    _myHostedIds.remove(meetingId);
  }

  bool isHost(Meeting m) => _myHostedIds.contains(m.id);
  bool isPending(Meeting m) => _myPendingIds.contains(m.id);
  bool isJoined(Meeting m) => _myJoinedIds.contains(m.id);

  /// 새 모임을 추가하고 날짜 인덱스에 반영한다. 만든 사람을 방장·참가자로 둔다.
  void add(Meeting m) {
    _all.add(m);
    _byDay.putIfAbsent(_key(m.startTime), () => []).add(m);
    _myJoinedIds.add(m.id);
    _myHostedIds.add(m.id);
  }

  /// 내가 참가/방장/대기 중인 모임 id 전체(브라우즈 교체 시 보존 대상).
  Set<String> get _myIds => {..._myJoinedIds, ..._myHostedIds, ..._myPendingIds};

  /// 홈 달력·목록에 노출되는 "브라우즈 모임"을 [meetings]로 통째 교체한다.
  /// 내 모임(joined/hosted/pending)은 채팅·내모임 탭이 참조하므로 보존한다.
  /// API에서 받은 목록을 반영할 때 사용한다.
  void replaceBrowse(List<Meeting> meetings) {
    final keep = _myIds;
    _all.removeWhere((m) => !keep.contains(m.id));
    for (final list in _byDay.values) {
      list.removeWhere((m) => !keep.contains(m.id));
    }
    for (final m in meetings) {
      _all.add(m);
      _byDay.putIfAbsent(_key(m.startTime), () => []).add(m);
    }
    _byDay.removeWhere((_, list) => list.isEmpty);
  }

  /// 해당 날짜 모임을 시작 시각 오름차순으로 반환한다.
  List<Meeting> meetingsOn(DateTime day) {
    final list = [...?_byDay[_key(day)]];
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return List.unmodifiable(list);
  }

  static const List<Member> _memberPool = [
    Member(nickname: '재호', birthYear: 1996, gender: Gender.male, mannerScore: 4.8, totalActivities: 32, timesMetWithMe: 3, intro: '주말마다 모임 다니는 걸 좋아해요!'),
    Member(nickname: '민지', birthYear: 1999, gender: Gender.female, mannerScore: 4.5, totalActivities: 18, timesMetWithMe: 1, intro: '조용히 즐기는 편이에요 :)'),
    Member(nickname: '수빈', birthYear: 2001, gender: Gender.female, mannerScore: 4.9, totalActivities: 47, timesMetWithMe: 5, intro: '새로운 사람 만나는 거 좋아합니다'),
    Member(nickname: '도윤', birthYear: 1994, gender: Gender.male, mannerScore: 4.2, totalActivities: 12, timesMetWithMe: 0, intro: '처음이라 조금 떨리네요!'),
    Member(nickname: '하늘', birthYear: 1998, gender: Gender.female, mannerScore: 5.0, totalActivities: 60, timesMetWithMe: 8, intro: '모임 자주 열어요. 편하게 오세요'),
    Member(nickname: '준영', birthYear: 1992, gender: Gender.male, mannerScore: 4.6, totalActivities: 25, timesMetWithMe: 2, intro: '맛집·카페 탐방 좋아함'),
    Member(nickname: '서연', birthYear: 2000, gender: Gender.female, mannerScore: 4.7, totalActivities: 21, timesMetWithMe: 1, intro: '운동 모임 위주로 나가요'),
    Member(nickname: '태현', birthYear: 1997, gender: Gender.male, mannerScore: 4.3, totalActivities: 9, timesMetWithMe: 0, intro: '게임·보드게임 환영!'),
  ];

  /// 멤버 풀 전체(읽기 전용). 신청자 mock 생성 등 외부 헬퍼가 참조한다.
  List<Member> get memberPool => List.unmodifiable(_memberPool);

  /// 모임 참가자. 서버 상세 조회로 받은 실제 참가자(방장 우선)가 있으면 그것을
  /// 쓰고, 없으면(목록/서버 미연동 모임) 결정적 mock으로 채운다.
  List<Member> participantsOf(Meeting m) {
    if (m.participants.isNotEmpty) return m.participants;
    final n = m.currentMembers.clamp(0, _memberPool.length);
    final offset = m.id.hashCode.abs() % _memberPool.length;
    return List.unmodifiable([
      for (var i = 0; i < n; i++) _memberPool[(offset + i) % _memberPool.length],
    ]);
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
    int max, {
    JoinMethod join = JoinMethod.approval,
  }) =>
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
        description:
            '$region에서 즐기는 ${c.label} 모임이에요. 부담 없이 신청해 주세요!',
        nearestStation: '$region 인근',
        cost: _costFor(c),
        joinMethod: join,
      );

  static MeetingCost _costFor(MeetingCategory c) {
    switch (c) {
      case MeetingCategory.hiking:
      case MeetingCategory.swimming:
        return const MeetingCost(CostType.free);
      case MeetingCategory.escapeRoom:
        return const MeetingCost(CostType.paid, amountWon: 22000);
      case MeetingCategory.etc:
        return const MeetingCost(CostType.hostPays);
      default:
        return const MeetingCost(CostType.split);
    }
  }

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
        DateTime(2026, 5, 20, 15, 0), '신림 카페거리', '신림', 'seoul-line2', 1, 4,
        join: JoinMethod.firstCome),
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
        DateTime(2026, 5, 21, 19, 0), '부산 서면', '서면', 'busan-line2', 2, 6,
        join: JoinMethod.firstCome),
    _m('n2', '광교산 등반', MeetingCategory.hiking,
        DateTime(2026, 5, 21, 6, 30), '수원 광교산', '수원', '경기-수원시', 4, 10),
    _m('n3', '판교 보드게임', MeetingCategory.boardGame,
        DateTime(2026, 5, 22, 20, 0), '성남 판교', '판교', '경기-성남시', 3, 6),
    _m('n4', '부산 PC방 정모', MeetingCategory.lol,
        DateTime(2026, 5, 23, 22, 0), '부산 남포동', '남포', 'busan-line1', 4, 5),
    _m('n5', '제주 오션뷰 카페', MeetingCategory.cafe,
        DateTime(2026, 5, 23, 10, 0), '제주 애월', '애월', '제주-제주시', 2, 4,
        join: JoinMethod.firstCome),
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
        DateTime(2026, 5, 29, 23, 0), '신촌', '신촌', 'seoul-line2', 4, 8,
        join: JoinMethod.firstCome),
    _m('n12', '청주 디저트 카페', MeetingCategory.cafe,
        DateTime(2026, 5, 30, 15, 0), '청주', '청주', '충북-청주시', 2, 5),
    _m('n13', '광주 롤 모임', MeetingCategory.lol,
        DateTime(2026, 5, 31, 20, 0), '광주 충장로', '충장로', 'gwangju-line1', 3, 5),
    _m('n14', '압구정 방탈출', MeetingCategory.escapeRoom,
        DateTime(2026, 6, 1, 14, 0), '압구정', '압구정', 'seoul-line3', 2, 6),
    _m('n15', '수원 점심 볼링', MeetingCategory.bowling,
        DateTime(2026, 6, 2, 12, 30), '수원역', '수원', '경기-수원시', 4, 8,
        join: JoinMethod.firstCome),
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

  /// 내가 참가/방장/대기 중인 모임 목록을 baseTime 기준 상대 시각으로 만든다.
  /// 분포: 진행중 1 + 다가오는 3(중 2 방장) + 종료된 4(중 2 방장) + 신청 대기 2.
  static _MySeed _buildMySeed(DateTime now) {
    Meeting at(
      String id,
      String title,
      MeetingCategory c,
      DateTime start,
      String place,
      String region, {
      int cur = 3,
      int max = 6,
      JoinMethod join = JoinMethod.approval,
    }) =>
        _m(id, title, c, start, place, region, 'seoul-line2', cur, max,
            join: join);

    final joined = <Meeting>[
      // 진행중 1 — now 기준 1시간 전 시작(진행중 윈도우 0~3h).
      at('me-ongoing', '망원 와인바 번개', MeetingCategory.drink,
          now.subtract(const Duration(hours: 1)), '망원 와인바', '망원'),

      // 다가오는 3 — 앞 2개는 내가 방장.
      at('me-up1-host', '주말 한강 러닝 모임', MeetingCategory.hiking,
          _at(now.add(const Duration(days: 1)), 8, 0), '여의도 한강공원', '여의도',
          cur: 4, max: 8),
      // 호스트지만 선착순 — 검토 버튼이 안 나오는 케이스(테스트용).
      at('me-up2-host', '판교 보드게임 정기 모임', MeetingCategory.boardGame,
          _at(now.add(const Duration(days: 3)), 19, 30), '판교 보드카페', '판교',
          cur: 3, max: 6, join: JoinMethod.firstCome),
      at('me-up3', '신촌 코노 한 시간', MeetingCategory.karaoke,
          _at(now.add(const Duration(days: 6)), 21, 0), '신촌 코인노래방', '신촌',
          cur: 2, max: 6),

      // 종료된 4 — 앞 2개는 내가 방장. 모두 채팅 만료 51h 이내.
      at('me-end1-host', '강남 카페 코딩', MeetingCategory.cafe,
          now.subtract(const Duration(hours: 5)), '강남 스타벅스', '강남',
          cur: 3, max: 5),
      at('me-end2-host', '잠실 볼링 한 게임', MeetingCategory.bowling,
          now.subtract(const Duration(hours: 14)), '잠실 볼링센터', '잠실',
          cur: 4, max: 6),
      at('me-end3', '홍대 방탈출 도전', MeetingCategory.escapeRoom,
          now.subtract(const Duration(hours: 26)), '홍대 비밀의방', '홍대',
          cur: 4, max: 4),
      at('me-end4', '성수 디저트 카페 투어', MeetingCategory.cafe,
          now.subtract(const Duration(hours: 40)), '성수 카페거리', '성수',
          cur: 3, max: 4),
    ];

    final pending = <Meeting>[
      at('me-pending1', '잠실 야구 직관 같이 가요', MeetingCategory.etc,
          _at(now.add(const Duration(days: 2)), 18, 30), '잠실야구장', '잠실',
          cur: 5, max: 8),
      at('me-pending2', '북한산 새벽 등반', MeetingCategory.hiking,
          _at(now.add(const Duration(days: 9)), 6, 0), '북한산 우이분소', '우이',
          cur: 6, max: 12),
    ];

    return _MySeed(
      meetings: [...joined, ...pending],
      joinedIds: {for (final m in joined) m.id},
      hostedIds: {'me-up1-host', 'me-up2-host', 'me-end1-host', 'me-end2-host'},
      pendingIds: {for (final m in pending) m.id},
    );
  }

  /// 같은 날의 특정 시·분으로 맞춰진 DateTime.
  static DateTime _at(DateTime day, int hour, int minute) =>
      DateTime(day.year, day.month, day.day, hour, minute);
}

class _MySeed {
  _MySeed({
    required this.meetings,
    required this.joinedIds,
    required this.hostedIds,
    required this.pendingIds,
  });

  final List<Meeting> meetings;
  final Set<String> joinedIds;
  final Set<String> hostedIds;
  final Set<String> pendingIds;
}
