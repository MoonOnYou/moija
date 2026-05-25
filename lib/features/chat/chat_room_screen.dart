import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/meeting_repository.dart';
import '../../models/meeting.dart';
import '../../theme/app_colors.dart';
import 'chat_message.dart';
import 'chat_room_drawer.dart';

/// 모임 채팅방 화면. 리스트에서 채팅 셀을 누르면 진입한다.
class ChatRoomScreen extends StatelessWidget {
  const ChatRoomScreen({
    super.key,
    required this.repository,
    required this.meeting,
  });

  final MeetingRepository repository;
  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    final participants = repository.participantsOf(meeting);
    final messages = mockMessagesFor(meeting, participants);

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
        items.add(_MyBubble(message: msg));
      } else {
        items.add(_OtherBubble(message: msg));
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        title: Text(meeting.title,
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
          ChatRoomDrawer(repository: repository, meeting: meeting),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: items,
      ),
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

/// 좌측 정렬되는 타인 메시지(닉네임 + 말풍선 + 시간).
class _OtherBubble extends StatelessWidget {
  const _OtherBubble({required this.message});
  final ChatMessage message;

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
            ],
          ),
        ],
      ),
    );
  }
}

/// 우측 정렬되는 내 메시지(시간 + 말풍선).
class _MyBubble extends StatelessWidget {
  const _MyBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('a h:mm', 'ko_KR').format(message.sentAt);
    return Padding(
      padding: const EdgeInsets.fromLTRB(60, 4, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textTertiary)),
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: const BoxDecoration(
                color: AppColors.textInfo,
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
