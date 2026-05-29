import 'package:flutter/material.dart';
import '../../models/meeting.dart';
import '../../theme/app_colors.dart';
import 'chat_preview.dart';

/// 채팅 리스트 한 줄. (docs/page/17_채팅방_셀.png 참고)
class ChatRoomCell extends StatelessWidget {
  const ChatRoomCell({
    super.key,
    required this.meeting,
    required this.timeLabel,
    this.preview,
    this.onTap,
    this.isHost = false,
  });

  final Meeting meeting;

  /// 우측 상단 시간 라벨(D-N / 시작 시각 / 남은 시간 등).
  final String timeLabel;

  /// 주입하지 않으면 모임 id로 결정적 목 데이터를 만든다.
  final ChatPreview? preview;

  final VoidCallback? onTap;

  /// 내가 방장인 모임이면 제목 옆 "방장" 칩이 표시된다.
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    final chat = preview ?? ChatPreview.forMeeting(meeting);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(meeting.category.icon,
                  size: 24, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(meeting.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                      if (isHost) ...[
                        const SizedBox(width: 6),
                        const _HostChip(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${chat.lastSender}: ${chat.lastMessage}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(timeLabel,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textTertiary)),
                const SizedBox(height: 6),
                if (chat.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    constraints: const BoxConstraints(minWidth: 20),
                    decoration: BoxDecoration(
                      color: AppColors.textDanger,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${chat.unreadCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  )
                else
                  // 배지 자리만큼 비워두어 시간 라벨 위치가 흔들리지 않게 한다.
                  const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HostChip extends StatelessWidget {
  const _HostChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.bgInfo,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('방장',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textInfo)),
    );
  }
}
