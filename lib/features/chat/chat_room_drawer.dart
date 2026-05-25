import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/meeting_repository.dart';
import '../../models/meeting.dart';
import '../../models/member.dart';
import '../../shell/app_navigation.dart';
import '../../theme/app_colors.dart';

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
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(m.nickname,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text(_memberSummary(m),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textTertiary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_memberActivity(m),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderTertiary),
            ListTile(
              leading: const Icon(Icons.block_rounded,
                  color: AppColors.textPrimary),
              title: const Text('차단하기'),
              onTap: () {
                Navigator.of(ctx).pop();
                _toast(context, '${m.nickname}님을 차단했어요');
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined,
                  color: AppColors.textDanger),
              title: const Text('신고하기',
                  style: TextStyle(color: AppColors.textDanger)),
              onTap: () {
                Navigator.of(ctx).pop();
                _toast(context, '${m.nickname}님 신고를 접수했어요');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('모임 나가기'),
        content: Text('"${meeting.title}" 모임에서 나갈까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.textDanger),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    repository.leave(meeting.id);
    myMeetingsRevision.value++;
    // drawer 닫기 + 채팅방 화면 pop → 내모임 리스트로 돌아간다.
    Navigator.of(context).pop();
    Navigator.of(context).pop();
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
          _InfoRow(icon: Icons.schedule, text: timeLabel),
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.place_outlined, text: meeting.placeLabel),
          const SizedBox(height: 6),
          _InfoRow(
              icon: Icons.payments_outlined, text: meeting.cost.display),
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.people_outline, text: _membersLine(meeting)),
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
