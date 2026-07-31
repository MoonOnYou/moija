import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/api/chat_api.dart';
import '../../data/chat/chat_socket.dart';
import '../../data/meeting_repository.dart';
import '../../models/meeting.dart';
import '../../theme/app_colors.dart';
import 'chat_message.dart';
import 'chat_preview.dart';
import 'chat_room_drawer.dart';

/// 모임 채팅방 화면. 리스트에서 채팅 셀을 누르면 진입한다.
///
/// [liveMeetingId]/[liveParticipantId]/[liveNickname]가 모두 주어지면 **라이브 모드**로
/// 실제 서버(REST 히스토리 + WebSocket 실시간)에 붙는다. 없으면 기존 mock 모드다.
/// TODO(auth): 라이브 파라미터는 개발용 브리지(ChatDevConfig)에서 온다. 인증 연동 시
/// 로그인 사용자/참여 모임으로 대체한다.
class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.repository,
    required this.meeting,
    this.liveMeetingId,
    this.liveParticipantId,
    this.liveNickname,
  });

  final MeetingRepository repository;
  final Meeting meeting;

  final String? liveMeetingId;
  final int? liveParticipantId;
  final String? liveNickname;

  bool get isLive =>
      liveMeetingId != null &&
      liveParticipantId != null &&
      liveNickname != null;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  // 라이브 모드 상태.
  final List<ChatMessage> _live = <ChatMessage>[];
  bool _liveLoading = false;
  String? _liveError;
  ChatSocket? _socket;
  StreamSubscription<ChatSocketEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    if (widget.isLive) _initLive();
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _socket?.dispose();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _initLive() async {
    setState(() {
      _liveLoading = true;
      _liveError = null;
    });
    try {
      final history = await fetchMessages(
        meetingId: widget.liveMeetingId!,
        participantId: widget.liveParticipantId!,
        myNickname: widget.liveNickname!,
      );
      if (!mounted) return;
      setState(() {
        _live
          ..clear()
          ..addAll(history);
        _liveLoading = false;
      });

      final socket = ChatSocket(
        meetingId: widget.liveMeetingId!,
        participantId: widget.liveParticipantId!,
        myNickname: widget.liveNickname!,
      );
      await socket.connect();
      if (!mounted) {
        await socket.dispose();
        return;
      }
      _socket = socket;
      _eventSub = socket.events.listen(_onEvent, onError: (_) {});
      _markLastRead(); // 방을 보고 있으니 진입 즉시 읽음 처리.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _liveLoading = false;
        _liveError = '$e';
      });
    }
  }

  void _onEvent(ChatSocketEvent event) {
    if (!mounted) return;
    switch (event) {
      case ChatMessageEvent(:final message):
        setState(() {
          final idx = _live.indexWhere((m) => m.id == message.id);
          if (idx >= 0) {
            _live[idx] = message;
          } else {
            _live.add(message);
          }
          _live.sort((a, b) => a.sentAt.compareTo(b.sentAt));
        });
        _scrollToBottom();
        _markLastRead(); // 보고 있는 중 → 새 메시지도 즉시 읽음.
      case ChatReadEvent(:final unread):
        setState(() {
          for (var i = 0; i < _live.length; i++) {
            final c = unread[_live[i].id];
            if (c != null) _live[i] = _live[i].copyWith(unreadCount: c);
          }
        });
    }
  }

  /// 마지막 사용자 메시지까지 읽음으로 표시한다(라이브 전용).
  void _markLastRead() {
    ChatMessage? last;
    for (final m in _live) {
      if (!m.isSystem) last = m;
    }
    if (last != null) _socket?.read(last.id);
  }

  void _scrollToBottom() {
    // reverse 리스트라 최신은 offset 0(화면 하단).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (widget.isLive) {
      // 서버 에코(message.new)로 화면에 반영되므로 낙관적 추가는 하지 않는다.
      _socket?.send(text);
      _controller.clear();
      return;
    }

    setState(() {
      // 저장소에 쌓아 둬야 방을 나갔다 와도 남고, 내모임 미리보기도 같이 갱신된다.
      widget.repository.addSentMessage(
        widget.meeting.id,
        ChatMessage(
          id: 'me-${DateTime.now().microsecondsSinceEpoch}',
          type: ChatMessageType.user,
          text: text,
          sentAt: DateTime.now(),
          sender: kMyNickname,
          mine: true,
        ),
      );
      _controller.clear();
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.meeting;

    // 라이브/mock에 따라 메시지 목록과 안읽음 계산 소스를 정한다.
    final List<ChatMessage> messages;
    final int Function(ChatMessage) unreadOf;
    if (widget.isLive) {
      messages = _live;
      unreadOf = (msg) => msg.unreadCount; // 서버 권위 값.
    } else {
      final participants = widget.repository.participantsOf(m);
      // 미리보기(ChatPreview)와 같은 소스를 써야 마지막 메시지가 어긋나지 않는다.
      messages = mockRoomMessages(m, widget.repository);
      // 카카오톡식 "안 읽은 사람 수"(말풍선당). 0이면 지도에 없다.
      final unread = unreadCountsFor(messages, participants.length);
      unreadOf = (msg) => unread[msg.id] ?? 0;
    }

    // 날짜가 바뀔 때마다 _DateDivider 한 줄을 끼워 넣어 펼친다.
    final items = <Widget>[];
    DateTime? lastDay;
    for (final msg in messages) {
      final day = DateTime(msg.sentAt.year, msg.sentAt.month, msg.sentAt.day);
      if (lastDay == null || day != lastDay) {
        items.add(_DateDivider(day));
        lastDay = day;
      }
      if (msg.isSystem) {
        items.add(_SystemLine(text: msg.text));
      } else if (msg.mine) {
        items.add(_MyBubble(message: msg, unreadCount: unreadOf(msg)));
      } else {
        items.add(_OtherBubble(message: msg, unreadCount: unreadOf(msg)));
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      // 우측 가장자리 드래그가 뒤로가기 제스처와 겹쳐 어색하므로 햄버거 버튼으로만 열도록.
      endDrawerEnableOpenDragGesture: false,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        title: Text(m.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              tooltip: '더보기',
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer:
          ChatRoomDrawer(repository: widget.repository, meeting: m),
      body: Column(
        children: [
          Expanded(child: _buildBody(items)),
          _MessageComposer(
            controller: _controller,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<Widget> items) {
    if (widget.isLive && _liveLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.isLive && _liveError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '채팅을 불러오지 못했습니다.\n$_liveError',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      );
    }
    // reverse:true 로 최신 메시지를 화면 하단에 고정한다.
    // 키보드가 올라와 viewport가 줄어도 최신 메시지가 자동으로 따라 올라온다.
    return ListView(
      controller: _scroll,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: items.reversed.toList(growable: false),
    );
  }
}

/// 가운데 정렬되는 날짜 구분선("2026년 5월 25일 (월)").
class _DateDivider extends StatelessWidget {
  const _DateDivider(this.day);
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('y년 M월 d일 (E)', 'ko_KR').format(day);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.borderTertiary, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textTertiary)),
          ),
          const Expanded(child: Divider(color: AppColors.borderTertiary, height: 1)),
        ],
      ),
    );
  }
}

/// 가운데 정렬되는 시스템 알림(채팅방 생성·입장 안내 등).
class _SystemLine extends StatelessWidget {
  const _SystemLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.bgTertiary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ),
      ),
    );
  }
}

/// 시간 옆에 붙는 작은 "안 읽은 사람 수"(카카오톡식 노란 숫자). 0이면 그리지 않는다.
class _UnreadCount extends StatelessWidget {
  const _UnreadCount(this.count);
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Text('$count',
        style: const TextStyle(
            fontSize: 10,
            height: 1.0,
            fontWeight: FontWeight.w700,
            color: AppColors.amber));
  }
}

/// 좌측 정렬되는 타인 메시지(닉네임 + 말풍선 + 시간).
class _OtherBubble extends StatelessWidget {
  const _OtherBubble({required this.message, this.unreadCount = 0});
  final ChatMessage message;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('a h:mm', 'ko_KR').format(message.sentAt);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 60, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.sender != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(message.sender!,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                    border: Border.all(
                        color: AppColors.borderTertiary, width: 0.5),
                  ),
                  child: Text(message.text,
                      style: const TextStyle(
                          fontSize: 14, height: 1.35)),
                ),
              ),
              const SizedBox(width: 6),
              Text(time,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textTertiary)),
              if (unreadCount > 0) ...[
                const SizedBox(width: 4),
                _UnreadCount(unreadCount),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 우측 정렬되는 내 메시지(시간 + 말풍선).
class _MyBubble extends StatelessWidget {
  const _MyBubble({required this.message, this.unreadCount = 0});
  final ChatMessage message;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('a h:mm', 'ko_KR').format(message.sentAt);
    return Padding(
      padding: const EdgeInsets.fromLTRB(60, 4, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (unreadCount > 0) ...[
            _UnreadCount(unreadCount),
            const SizedBox(width: 4),
          ],
          Text(time,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textTertiary)),
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: const BoxDecoration(
                color: AppColors.coral,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Text(message.text,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.white, height: 1.35)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 본문 하단의 입력창 + 전송 버튼.
/// 키보드 엔터는 줄바꿈으로 동작하고, 전송은 우측 아이콘에서만 일어난다.
class _MessageComposer extends StatelessWidget {
  const _MessageComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgPrimary,
          border: Border(
            top: BorderSide(color: AppColors.borderTertiary, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  key: const Key('chat-composer-input'),
                  controller: controller,
                  minLines: 1,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(fontSize: 14, height: 1.35),
                  decoration: InputDecoration(
                    hintText: '메시지 입력',
                    hintStyle: const TextStyle(
                        fontSize: 14, color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.bgSecondary,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, child) {
                final enabled = value.text.trim().isNotEmpty;
                return IconButton(
                  key: const Key('chat-composer-send'),
                  tooltip: '전송',
                  onPressed: enabled ? onSend : null,
                  icon: const Icon(Icons.send_rounded),
                  color: enabled
                      ? AppColors.textInfo
                      : AppColors.textTertiary,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
