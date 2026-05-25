import 'package:flutter/material.dart';
import '../../data/meeting_repository.dart';
import '../../models/join_method.dart';
import '../../models/meeting.dart';
import '../../shell/app_navigation.dart';
import '../../theme/app_colors.dart';
import '../meeting/applicant_review_screen.dart';
import 'chat_preview.dart';
import 'chat_room_cell.dart';
import 'chat_room_screen.dart';

/// 내모임 화면. 내가 신청 대기 중이거나 참가한 모임만 노출한다.
/// 섹션 순서: 신청 대기 → 진행중 → 다가오는 → 종료된.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.repository, this.now});

  final MeetingRepository repository;

  /// 테스트에서 단계 판정 기준 시각을 주입한다.
  final DateTime? now;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    final n = widget.now ?? DateTime.now();
    final repo = widget.repository;

    final pending = <Meeting>[];
    final upcoming = <Meeting>[];
    final ongoing = <Meeting>[];
    final ended = <Meeting>[];

    for (final m in repo.allMeetings) {
      if (repo.isPending(m)) {
        pending.add(m);
        continue;
      }
      if (!repo.isJoined(m)) continue;
      if (!chatStillAlive(m, n)) continue;
      switch (meetingPhase(m, n)) {
        case MeetingPhase.upcoming:
          upcoming.add(m);
        case MeetingPhase.ongoing:
          ongoing.add(m);
        case MeetingPhase.ended:
          ended.add(m);
      }
    }
    pending.sort((a, b) => a.startTime.compareTo(b.startTime));
    upcoming.sort((a, b) => a.startTime.compareTo(b.startTime));
    ongoing.sort((a, b) => a.startTime.compareTo(b.startTime));
    ended.sort((a, b) => b.startTime.compareTo(a.startTime));

    final hasAny =
        pending.isNotEmpty ||
        ongoing.isNotEmpty ||
        upcoming.isNotEmpty ||
        ended.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        title: const Text(
          '내모임',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: !hasAny
            ? CustomScrollView(
                // 빈 상태에서도 당겨서 새로고침이 동작하도록 항상 스크롤 가능하게.
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: const [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        '아직 참여 중인 모임이 없어요',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (pending.isNotEmpty) ...[
                    const _SectionHeader('신청 대기중'),
                    for (final m in pending)
                      _PendingMeetingCell(
                        meeting: m,
                        onCancel: () => _confirmCancel(m),
                      ),
                  ],
                  if (ongoing.isNotEmpty) ...[
                    const _SectionHeader('진행중인 모임'),
                    for (final m in ongoing)
                      ChatRoomCell(
                        meeting: m,
                        timeLabel: ongoingLabel(m),
                        isHost: repo.isHost(m),
                        onTap: () => _openChatRoom(m),
                      ),
                  ],
                  if (upcoming.isNotEmpty) ...[
                    const _SectionHeader('다가오는 모임'),
                    for (final m in upcoming) ...[
                      ChatRoomCell(
                        meeting: m,
                        timeLabel: upcomingLabel(m, n),
                        isHost: repo.isHost(m),
                        onTap: () => _openChatRoom(m),
                      ),
                      // 선착순은 신청 검토 단계가 없으므로 승인제일 때만 노출.
                      if (repo.isHost(m) && m.joinMethod == JoinMethod.approval)
                        _HostActionButton(
                          icon: Icons.fact_check_outlined,
                          label: '신청자 ${pendingApplicantsFor(m)}명 검토하기',
                          onPressed: () => _openApplicantReview(m),
                        ),
                    ],
                  ],
                  if (ended.isNotEmpty) ...[
                    const _SectionHeader('종료된 모임'),
                    for (final m in ended) ...[
                      ChatRoomCell(
                        meeting: m,
                        timeLabel: endedLabel(m, n),
                        isHost: repo.isHost(m),
                        onTap: () => _openChatRoom(m),
                      ),
                      if (repo.isHost(m))
                        _HostActionButton(
                          icon: Icons.star_outline_rounded,
                          label: '팀원 매너 평가하기',
                          onPressed: () {},
                        ),
                    ],
                  ],
                  const SizedBox(height: 12),
                ],
              ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    // mock 데이터라 별도 fetch는 없고, 약간의 지연 후 리스트만 다시 그린다.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() {});
  }

  Future<void> _openApplicantReview(Meeting m) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ApplicantReviewScreen(repository: widget.repository, meeting: m),
      ),
    );
  }

  Future<void> _openChatRoom(Meeting m) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ChatRoomScreen(repository: widget.repository, meeting: m),
      ),
    );
    // 채팅방에서 모임 나가기 했을 수 있으니 리스트 갱신.
    if (mounted) setState(() {});
  }

  Future<void> _confirmCancel(Meeting m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('신청 취소'),
        content: Text('"${m.title}" 신청을 취소할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.textDanger),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => widget.repository.cancelPending(m.id));
      myMeetingsRevision.value++;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// 신청 대기중 셀. 오른쪽 안읽음 배지 자리에 "신청 취소" 버튼이 들어간다.
class _PendingMeetingCell extends StatelessWidget {
  const _PendingMeetingCell({required this.meeting, required this.onCancel});

  final Meeting meeting;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: meeting.category.chipBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              meeting.category.icon,
              size: 24,
              color: meeting.category.chipForeground,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meeting.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meeting.description.isNotEmpty
                      ? meeting.description
                      : meeting.placeLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textDanger,
              side: const BorderSide(color: AppColors.borderTertiary),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('신청 취소'),
          ),
        ],
      ),
    );
  }
}

/// 셀 아래에 가로로 길게 들어가는 방장 액션 버튼.
class _HostActionButton extends StatelessWidget {
  const _HostActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.bgSecondary,
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
