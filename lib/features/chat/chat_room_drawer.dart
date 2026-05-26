import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/meeting_repository.dart';
import '../../models/meeting.dart';
import '../../models/member.dart';
import '../../shell/app_navigation.dart';
import '../../theme/app_colors.dart';
import '../common/block_reason_screen.dart';

/// 채팅방 우측에서 열리는 더보기 패널.
/// 모임 정보 + 팀원 리스트(차단·신고 액션) + 모임 나가기.
class ChatRoomDrawer extends StatelessWidget {
  const ChatRoomDrawer({
    super.key,
    required this.repository,
    required this.meeting,
  });

  final MeetingRepository repository;
  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    final participants = repository.participantsOf(meeting);

    return Drawer(
      backgroundColor: AppColors.bgPrimary,
      child: SafeArea(
        child: Column(
          children: [
            _Header(meeting: meeting),
            const Divider(height: 1, color: AppColors.borderTertiary),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text('팀원',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Text('${participants.length}/${meeting.maxMembers}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textTertiary)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: participants.length,
                itemBuilder: (ctx, i) => _MemberTile(
                  key: ValueKey('member-tile-$i'),
                  member: participants[i],
                  isHost: i == 0,
                  onTap: () => _showMemberSheet(ctx, participants[i]),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.borderTertiary),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLeave(context),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('모임 나가기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDanger,
                    side: const BorderSide(color: AppColors.borderTertiary),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMemberSheet(BuildContext context, Member m) async {
    final isMale = m.gender == Gender.male;
    final avatarBg = isMale ? AppColors.bgInfo : AppColors.bgPink;
    final avatarFg = isMale ? AppColors.textInfo : AppColors.textPink;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: avatarBg,
                child: Text(m.nickname.characters.first,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: avatarFg)),
              ),
              const SizedBox(height: 12),
              Text(m.nickname,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(_memberSummary(m),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(_memberActivity(m),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.block_rounded, size: 16),
                  label: const Text('차단하기'),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final reason =
                        await BlockReasonScreen.show(context, m.nickname);
                    if (reason != null && context.mounted) {
                      _toast(context, '${m.nickname}님을 차단했어요');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.borderTertiary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.flag_rounded, size: 16),
                  label: const Text('신고하기'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _toast(context, '${m.nickname}님 신고를 접수했어요');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.textDanger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary),
                child: const Text('닫기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final isHost = repository.isHost(meeting);
    final participants = repository.participantsOf(meeting);
    // 호스트(=나) 다음 자리부터를 다른 팀원으로 본다(mock 단순화).
    final others = isHost && participants.length > 1
        ? participants.sublist(1)
        : const <Member>[];

    final result = await showDialog<_LeaveResult>(
      context: context,
      builder: (ctx) => _LeaveMeetingDialog(isHost: isHost, others: others),
    );
    if (result == null) return;
    if (!context.mounted) return;

    if (isHost && result.nextHost != null) {
      _toast(context, '${result.nextHost}님이 새 방장이 되었어요');
    }
    repository.leave(meeting.id);
    myMeetingsRevision.value++;
    Navigator.of(context).pop(); // drawer
    Navigator.of(context).pop(); // chat room screen
  }

  void _toast(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ));
  }
}

String _memberSummary(Member m) => '${m.birthYear}년생 · ${m.gender.label}';

String _memberActivity(Member m) =>
    '활동 ${m.totalActivities}회 · 나와 ${m.timesMetWithMe}번 만남';

class _Header extends StatelessWidget {
  const _Header({required this.meeting});
  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    final timeLabel =
        DateFormat('M월 d일 (E) a h:mm', 'ko_KR').format(meeting.startTime);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: meeting.category.chipBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(meeting.category.icon,
                    color: meeting.category.chipForeground, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meeting.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(meeting.categoryLabel,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.schedule_rounded, text: timeLabel),
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.place_rounded, text: meeting.placeLabel),
          const SizedBox(height: 6),
          _InfoRow(
              icon: Icons.payments_rounded, text: meeting.cost.display),
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.people_rounded, text: _membersLine(meeting)),
        ],
      ),
    );
  }
}

String _membersLine(Meeting m) {
  final left = m.spotsLeft;
  final tail = left > 0 ? '$left자리 남음' : '정원 마감';
  return '${m.currentMembers}/${m.maxMembers}명 · $tail';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.35)),
        ),
      ],
    );
  }
}

/// 나가기 다이얼로그 pop 결과. null이면 취소.
class _LeaveResult {
  const _LeaveResult({this.nextHost});

  /// 호스트가 나갈 때 위임받을 다음 방장 닉네임. 팀원이거나 혼자였으면 null.
  final String? nextHost;
}

class _LeaveMeetingDialog extends StatefulWidget {
  const _LeaveMeetingDialog({required this.isHost, required this.others});

  final bool isHost;
  final List<Member> others;

  @override
  State<_LeaveMeetingDialog> createState() => _LeaveMeetingDialogState();
}

class _LeaveMeetingDialogState extends State<_LeaveMeetingDialog> {
  String? _nextHost;

  bool get _needsNextHost => widget.isHost && widget.others.isNotEmpty;
  bool get _canLeave => !_needsNextHost || _nextHost != null;

  @override
  Widget build(BuildContext context) {
    final diamond = widget.isHost ? 300 : 50;

    return Dialog(
      backgroundColor: AppColors.bgPrimary,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 원형 아이콘.
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.bgPink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    size: 28, color: AppColors.textDanger),
              ),
              const SizedBox(height: 14),
              const Text('모임을 정말 나가시겠어요?',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),

              // 안내 카드 묶음.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NoticeRow(
                        icon: Icons.diamond_rounded,
                        iconColor: AppColors.textInfo,
                        text: '$diamond 다이아는 환불되지 않아요'),
                    const SizedBox(height: 10),
                    const _NoticeRow(
                        icon: Icons.star_outline_rounded,
                        iconColor: AppColors.textWarning,
                        text: '나가도 팀원들이 내 매너점수를 평가할 수 있어요'),
                    if (_needsNextHost) ...[
                      const SizedBox(height: 10),
                      const _NoticeRow(
                          icon: Icons.swap_horiz_rounded,
                          iconColor: AppColors.textDanger,
                          text: '다른 팀원에게 방장을 넘겨줘야 해요'),
                    ],
                  ],
                ),
              ),

              if (_needsNextHost) ...[
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('다음 방장 선택',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final m in widget.others)
                          _NextHostCard(
                            key: ValueKey('next-host-${m.nickname}'),
                            member: m,
                            selected: _nextHost == m.nickname,
                            onTap: () =>
                                setState(() => _nextHost = m.nickname),
                          ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('leave-cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(
                            color: AppColors.borderTertiary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      key: const Key('leave-confirm'),
                      onPressed: _canLeave
                          ? () => Navigator.of(context)
                              .pop(_LeaveResult(nextHost: _nextHost))
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.textDanger,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.bgTertiary,
                        disabledForegroundColor: AppColors.textTertiary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('나가기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 다음 방장 후보 카드. 탭으로 선택, 선택 시 보더·배경·체크 아이콘이 강조된다.
class _NextHostCard extends StatelessWidget {
  const _NextHostCard({
    super.key,
    required this.member,
    required this.selected,
    required this.onTap,
  });

  final Member member;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isMale = member.gender == Gender.male;
    final avatarBg = isMale ? AppColors.bgInfo : AppColors.bgPink;
    final avatarFg = isMale ? AppColors.textInfo : AppColors.textPink;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.bgInfo : AppColors.bgPrimary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? AppColors.textInfo
                    : AppColors.borderTertiary,
                width: selected ? 1.4 : 0.5,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: avatarBg,
                  child: Text(member.nickname.characters.first,
                      style: TextStyle(
                          color: avatarFg,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.nickname,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 1),
                      Text(_memberSummary(member),
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary)),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? AppColors.textInfo
                      : AppColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    super.key,
    required this.member,
    required this.isHost,
    required this.onTap,
  });

  final Member member;
  final bool isHost;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = member.gender == Gender.male
        ? AppColors.bgInfo
        : AppColors.bgPink;
    final fg = member.gender == Gender.male
        ? AppColors.textInfo
        : AppColors.textPink;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color,
              child: Text(member.nickname.characters.first,
                  style: TextStyle(
                      color: fg, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(member.nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      Text(_memberSummary(member),
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary)),
                      if (isHost) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.bgInfo,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('방장',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textInfo)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(_memberActivity(member),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}
