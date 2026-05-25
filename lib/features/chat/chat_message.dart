import '../../models/meeting.dart';
import '../../models/member.dart';

/// 메시지 종류. 시스템 알림은 본문 가운데에, 사용자 메시지는 좌/우 정렬된다.
enum ChatMessageType { system, user }

/// 채팅방 한 줄.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.type,
    required this.text,
    required this.sentAt,
    this.sender,
    this.mine = false,
  });

  final String id;
  final ChatMessageType type;
  final String text;
  final DateTime sentAt;

  /// 시스템 메시지면 null.
  final String? sender;

  /// 내가 보낸 메시지면 true → 화면 우측 정렬.
  final bool mine;

  bool get isSystem => type == ChatMessageType.system;
}

/// 채팅 미리보기·말풍선 양쪽에서 가리키는 "나"의 닉네임. mock 일관성용.
const String kMyNickname = '나';

const List<String> _chatLines = <String>[
  '안녕하세요! 잘 부탁드려요',
  '어디서 만날까요?',
  '저는 4번 출구가 편해요',
  '오늘 날씨 좋네요 ☀️',
  '도착하면 톡 드릴게요',
  '저 10분 정도 늦을 것 같아요 ㅠ',
  '먼저 자리 잡고 있어 주세요',
  '메뉴 미리 봐 놨어요',
  '오늘 잘 부탁드려요!',
  '다음 모임도 같이 해요 :)',
  '비 와서 우산 챙겨요',
  '도착 1분 전!',
];

/// 모임 id를 시드로 결정적인 mock 메시지 시퀀스를 만든다.
/// 시스템 알림(생성·입장) + 멤버별 짧은 인사 + 내 메시지 1~2개 + 다음 날 메시지 1개.
List<ChatMessage> mockMessagesFor(Meeting m, List<Member> participants) {
  if (participants.isEmpty) return const [];

  final h = m.id.hashCode.abs();
  final host = participants.first.nickname;
  final creation = m.startTime.subtract(const Duration(days: 3, hours: 2));

  final out = <ChatMessage>[
    ChatMessage(
      id: '${m.id}-sys-create',
      type: ChatMessageType.system,
      text: '채팅방이 생성되었습니다',
      sentAt: creation,
    ),
    ChatMessage(
      id: '${m.id}-sys-in-$host',
      type: ChatMessageType.system,
      text: '$host님이 입장하셨습니다',
      sentAt: creation.add(const Duration(seconds: 1)),
    ),
    ChatMessage(
      id: '${m.id}-msg-host-greet',
      type: ChatMessageType.user,
      sender: host,
      text: '안녕하세요, 모임 들어와주셔서 감사해요!',
      sentAt: creation.add(const Duration(minutes: 4)),
    ),
  ];

  // 나머지 멤버 입장 + 한 줄씩 인사.
  for (var i = 1; i < participants.length; i++) {
    final p = participants[i];
    final t = creation.add(Duration(hours: 2 * i, minutes: (i * 7) % 30));
    out.add(ChatMessage(
      id: '${m.id}-sys-in-${p.nickname}',
      type: ChatMessageType.system,
      text: '${p.nickname}님이 입장하셨습니다',
      sentAt: t,
    ));
    out.add(ChatMessage(
      id: '${m.id}-msg-${p.nickname}',
      type: ChatMessageType.user,
      sender: p.nickname,
      text: _chatLines[(h + i) % _chatLines.length],
      sentAt: t.add(const Duration(minutes: 1, seconds: 30)),
    ));
  }

  // 내 메시지 1개 — 시작 5시간 전.
  out.add(ChatMessage(
    id: '${m.id}-msg-mine-1',
    type: ChatMessageType.user,
    sender: kMyNickname,
    text: '저도 잘 부탁드려요! 도착하면 톡 드릴게요',
    sentAt: m.startTime.subtract(const Duration(hours: 5)),
    mine: true,
  ));

  // 다음 날 호스트 메시지(또는 시작 직전) — 날짜 구분선 트리거.
  out.add(ChatMessage(
    id: '${m.id}-msg-host-d2',
    type: ChatMessageType.user,
    sender: host,
    text: _chatLines[(h + 3) % _chatLines.length],
    sentAt: m.startTime.subtract(const Duration(hours: 1)),
  ));

  out.sort((a, b) => a.sentAt.compareTo(b.sentAt));
  return out;
}
