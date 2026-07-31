import 'package:intl/intl.dart';
import '../../data/meeting_repository.dart';
import '../../models/join_method.dart';
import '../../models/meeting.dart';
import 'chat_message.dart';

/// 모임 채팅 단계. 채팅 리스트 섹션을 가른다.
enum MeetingPhase { upcoming, ongoing, ended }

/// 모임 종료 시각 정보가 없어, 시작 후 [kMeetingDuration]까지를 "진행중"으로 본다.
const Duration kMeetingDuration = Duration(hours: 3);

/// 모임이 끝난 뒤 채팅방이 유지되는 기간(안내 #22와 동일).
const Duration kChatLifetime = Duration(hours: 48);

/// 모임의 현재 단계.
MeetingPhase meetingPhase(Meeting m, DateTime now) {
  if (now.isBefore(m.startTime)) return MeetingPhase.upcoming;
  final endsAt = m.startTime.add(kMeetingDuration);
  if (now.isBefore(endsAt)) return MeetingPhase.ongoing;
  return MeetingPhase.ended;
}

/// 종료된 모임의 채팅방이 사라지는 시각.
DateTime chatExpiresAt(Meeting m) =>
    m.startTime.add(kMeetingDuration + kChatLifetime);

/// 채팅방이 아직 유지 중인지(만료 전인지).
bool chatStillAlive(Meeting m, DateTime now) =>
    now.isBefore(chatExpiresAt(m));

/// 다가오는 모임 라벨: D-Day / D-N (calendar day 기준).
String upcomingLabel(Meeting m, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final mDay = DateTime(m.startTime.year, m.startTime.month, m.startTime.day);
  final days = mDay.difference(today).inDays;
  return days <= 0 ? 'D-Day' : 'D-$days';
}

/// 진행중 모임 라벨: 모임 시작 시각(예: "오후 7:30").
String ongoingLabel(Meeting m) =>
    DateFormat('a h:mm', 'ko_KR').format(m.startTime);

/// 종료된 모임 라벨: 채팅방 만료까지 남은 시간.
String endedLabel(Meeting m, DateTime now) {
  final remaining = chatExpiresAt(m).difference(now);
  if (remaining.isNegative) return '곧 종료';
  if (remaining.inHours >= 24) {
    return '${remaining.inDays}일 남음';
  }
  if (remaining.inHours >= 1) {
    return '${remaining.inHours}시간 남음';
  }
  if (remaining.inMinutes >= 1) {
    return '${remaining.inMinutes}분 남음';
  }
  return '곧 종료';
}

/// mock 채팅방이 실제로 보여 주는 메시지 전체(오래된 → 최신).
/// 채팅방 화면과 미리보기가 같은 함수를 쓰게 해 내용이 어긋나지 않도록 한다.
List<ChatMessage> mockRoomMessages(Meeting m, MeetingRepository repo) => [
      ...mockMessagesFor(m, repo.participantsOf(m)),
      ...repo.sentMessagesOf(m.id),
    ];

/// 채팅방의 마지막 사용자 메시지(시스템 알림 제외). 없으면 null.
ChatMessage? lastChatMessageOf(Meeting m, MeetingRepository repo) {
  final messages = mockRoomMessages(m, repo);
  for (var i = messages.length - 1; i >= 0; i--) {
    if (!messages[i].isSystem) return messages[i];
  }
  return null;
}

/// 모임 채팅 미리보기(목 데이터). 모임 id 해시로 결정한다.
class ChatPreview {
  const ChatPreview({
    required this.lastSender,
    required this.lastMessage,
    required this.unreadCount,
  });

  final String lastSender;
  final String lastMessage;
  final int unreadCount;

  static const _messages = <String>[
    '안녕하세요!',
    '저 10분 늦어요 ㅠ',
    '출발했어요',
    '도착 1분 전!',
    '오늘 잘 부탁드려요',
    '어떻게 입고 갈까요?',
    '비가 와서 우산 챙겨요',
    '4번 출구에서 만나요',
    '다음에 또 봐요~',
    '오늘 너무 즐거웠어요',
  ];

  static const _senders = <String>[
    '민지', '재호', '수빈', '도윤', '하늘', '준영', '서연', '태현',
  ];

  /// 미리보기를 만든다.
  ///
  /// [repository]를 주면 채팅방과 **같은 소스**(mock 메시지 + 내가 보낸 메시지)의
  /// 마지막 사용자 메시지를 그대로 쓴다. 주지 않으면(=참가자를 알 수 없는 호출)
  /// 모임 id 해시 기반 목 문구로 폴백한다.
  /// 안읽음 수는 아직 읽음 상태 모델이 없어 예전처럼 id 해시로 만든다.
  factory ChatPreview.forMeeting(Meeting m, {MeetingRepository? repository}) {
    final h = m.id.hashCode.abs();
    // 0이 가장 흔하도록 분포: 5개 중 3개는 0, 1개는 1, 1개는 2~4.
    final unread = switch (h % 5) {
      0 || 1 || 2 => 0,
      3 => 1,
      _ => 2 + (h % 3),
    };

    final last = repository == null ? null : lastChatMessageOf(m, repository);
    if (last != null) {
      return ChatPreview(
        lastSender: last.sender ?? '',
        lastMessage: last.text,
        unreadCount: unread,
      );
    }

    return ChatPreview(
      lastSender: _senders[h % _senders.length],
      lastMessage: _messages[(h ~/ _senders.length) % _messages.length],
      unreadCount: unread,
    );
  }
}

/// 방장 액션(신청자 검토/매너 평가) 카드에 노출할 신청자 수.
/// 결정적으로 1~5 사이로 잡는다.
int pendingApplicantsFor(Meeting m) => 1 + (m.id.hashCode.abs() % 5);

/// 내모임 탭 배지에 쓰는 합계. 채팅 안읽음 + 방장 액션 카드 1개당 1.
/// 신청 대기는 채팅이 아직 없으므로 합산에서 제외한다.
int myMeetingsBadgeTotal(MeetingRepository repo, DateTime now) {
  var total = 0;
  for (final m in repo.allMeetings) {
    if (!repo.isJoined(m)) continue;
    if (!chatStillAlive(m, now)) continue;
    total += ChatPreview.forMeeting(m).unreadCount;
    if (repo.isHost(m)) {
      switch (meetingPhase(m, now)) {
        case MeetingPhase.upcoming:
          // 선착순은 검토 카드가 없으므로 합산에서 제외.
          if (m.joinMethod == JoinMethod.approval) total += 1;
        case MeetingPhase.ended:
          total += 1; // 팀원 매너 평가하기
        case MeetingPhase.ongoing:
          break;
      }
    }
  }
  return total;
}
