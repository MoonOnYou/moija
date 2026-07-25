import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../features/chat/chat_message.dart';

const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

/// 서버 → 클라이언트로 오는 실시간 이벤트.
sealed class ChatSocketEvent {
  const ChatSocketEvent();
}

/// 새 메시지(`message.new`). 자신이 보낸 메시지도 그룹 브로드캐스트로 되돌아온다.
class ChatMessageEvent extends ChatSocketEvent {
  const ChatMessageEvent(this.message);
  final ChatMessage message;
}

/// 읽음 갱신(`read.update`). `{messageId: 안읽음수}` 부분 맵.
class ChatReadEvent extends ChatSocketEvent {
  const ChatReadEvent(this.unread);
  final Map<String, int> unread;
}

/// 모임 채팅방 WebSocket 연결.
///
/// `ws(s)://<host>/ws/meetings/{meetingId}/?participant_id=<id>` 로 접속한다.
/// 방 멤버가 아니거나 잘못된 id면 서버가 즉시 연결을 닫는다.
/// TODO(auth): participant_id 쿼리를 인증 토큰으로 교체한다.
class ChatSocket {
  ChatSocket({
    required this.meetingId,
    required this.participantId,
    required this.myNickname,
  });

  final String meetingId;
  final int participantId;
  final String myNickname;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  final _controller = StreamController<ChatSocketEvent>.broadcast();

  /// 실시간 이벤트 스트림. 파싱 에러는 격리되어 스트림을 끊지 않는다.
  Stream<ChatSocketEvent> get events => _controller.stream;

  static String get _wsBase =>
      _baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');

  /// 연결한다. `channel.ready`가 완료돼야 접속 성공으로 본다.
  Future<void> connect() async {
    final uri = Uri.parse(
      '$_wsBase/ws/meetings/$meetingId/?participant_id=$participantId',
    );
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    await channel.ready;
    _sub = channel.stream.listen(
      _onRaw,
      onError: (Object e) => _controller.addError(e),
      onDone: () {
        if (!_controller.isClosed) _controller.close();
      },
    );
  }

  void _onRaw(dynamic raw) {
    if (_controller.isClosed) return;
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      switch (data['type']) {
        case 'message.new':
          _controller.add(ChatMessageEvent(ChatMessage.fromJson(
            data['message'] as Map<String, dynamic>,
            myNickname: myNickname,
          )));
        case 'read.update':
          final unread = (data['unread'] as Map<String, dynamic>?) ?? {};
          _controller.add(ChatReadEvent(
            unread.map((k, v) => MapEntry(k, (v as num).toInt())),
          ));
      }
    } catch (_) {
      // 알 수 없는 프레임은 무시(스트림 유지).
    }
  }

  /// 메시지 전송.
  void send(String text) {
    _channel?.sink.add(jsonEncode({'type': 'send', 'text': text}));
  }

  /// 읽음 위치 갱신.
  void read(String lastReadMessageId) {
    _channel?.sink.add(jsonEncode({
      'type': 'read',
      'last_read_message_id': int.parse(lastReadMessageId),
    }));
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _channel?.sink.close();
    if (!_controller.isClosed) await _controller.close();
  }
}
