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
    this.unreadCount = 0,
  });

  final String id;
  final ChatMessageType type;
  final String text;
  final DateTime sentAt;

  /// 시스템 메시지면 null.
  final String? sender;

  /// 내가 보낸 메시지면 true → 화면 우측 정렬.
  final bool mine;

  /// 이 메시지를 아직 안 읽은 인원 수(보낸 사람 제외). 서버가 권위 있게 계산해 준다.
  /// mock 모드에서는 [unreadCountsFor]로 별도 계산하므로 0으로 둔다.
  final int unreadCount;

  bool get isSystem => type == ChatMessageType.system;

  ChatMessage copyWith({int? unreadCount}) => ChatMessage(
        id: id,
        type: type,
        text: text,
        sentAt: sentAt,
        sender: sender,
        mine: mine,
        unreadCount: unreadCount ?? this.unreadCount,
      );

  /// 서버 메시지 JSON을 앱 모델로 변환한다.
  ///
  /// 서버 필드: `{id(int), type("user"|"system"), text, sent_at(ISO8601),
  /// sender(닉네임 문자열 or null), unread_count(int)}`.
  /// 서버는 sender를 닉네임으로만 주므로 [myNickname]과 비교해 [mine]을 유도한다.
  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    required String myNickname,
  }) {
    final rawType = json['type'] as String?;
    final type = rawType == 'system'
        ? ChatMessageType.system
        : ChatMessageType.user;
    final sender = json['sender'] as String?;
    return ChatMessage(
      id: json['id'].toString(),
      type: type,
      text: (json['text'] ?? '') as String,
      sentAt: DateTime.parse(json['sent_at'] as String).toLocal(),
      sender: sender,
      mine: type == ChatMessageType.user && sender == myNickname,
      unreadCount: (json['unread_count'] as int?) ?? 0,
    );
  }
}

/// 채팅 미리보기·말풍선 양쪽에서 가리키는 "나"의 닉네임. mock 일관성용.
const String kMyNickname = '나';

/// 각 사용자 메시지의 "안 읽은 사람 수"(카카오톡식)를 결정적으로 계산한다.
///
/// 실제 읽음 상태가 없으므로 "최신 메시지일수록 아직 안 읽은 사람이 많고,
/// 오래된 메시지는 모두 읽음"이라는 규칙으로 만든다. [ordered]는 오래된→최신
/// 순으로 정렬된 메시지, [participantCount]는 나를 제외한 참가자 수.
///
/// 메시지를 최신순(0,1,2…)으로 세어 `cap - 순위`를 보여 준다.
/// - cap = 내 메시지면 참가자 수, 상대 메시지면 참가자 수 − 1 (보낸 사람·나 제외).
/// - 0 이하이면 지도에 넣지 않아 말풍선에서 숨겨진다.
/// 시스템 메시지는 순위에서 제외한다.
Map<String, int> unreadCountsFor(
    List<ChatMessage> ordered, int participantCount) {
  final out = <String, int>{};
  var rank = 0; // 최신 사용자 메시지부터 0,1,2…
  for (var i = ordered.length - 1; i >= 0; i--) {
    final msg = ordered[i];
    if (msg.isSystem) continue;
    final cap = msg.mine ? participantCount : participantCount - 1;
    if (cap > 0) {
      final count = cap - rank;
      if (count > 0) out[msg.id] = count;
    }
    rank++;
  }
  return out;
}

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
