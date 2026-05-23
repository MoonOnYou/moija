import 'package:intl/intl.dart';
import '../../models/meeting.dart';

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

  /// 모임 id 해시로 결정적인 미리보기를 만든다(목).
  factory ChatPreview.forMeeting(Meeting m) {
    final h = m.id.hashCode.abs();
    // 0이 가장 흔하도록 분포: 5개 중 3개는 0, 1개는 1, 1개는 2~4.
    final unread = switch (h % 5) {
      0 || 1 || 2 => 0,
      3 => 1,
      _ => 2 + (h % 3),
    };
    return ChatPreview(
      lastSender: _senders[h % _senders.length],
      lastMessage: _messages[(h ~/ _senders.length) % _messages.length],
      unreadCount: unread,
    );
  }
}
