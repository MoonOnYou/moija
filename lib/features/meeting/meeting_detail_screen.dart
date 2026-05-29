import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/meeting_repository.dart';
import '../../data/wallet.dart';
import '../../models/join_method.dart';
import '../../models/meeting.dart';
import '../../shell/app_navigation.dart';
import '../../theme/app_colors.dart';
import '../common/notice_screen.dart';
import 'diamond_recharge_screen.dart';
import 'widgets/participant_card.dart';

class MeetingDetailScreen extends StatelessWidget {
  const MeetingDetailScreen({
    super.key,
    required this.meeting,
    required this.repository,
    this.diamonds = Wallet.myDiamonds,
  });

  final Meeting meeting;
  final MeetingRepository repository;
  final int diamonds;

  Future<void> _onApply(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (diamonds <= 50) {
      messenger.showSnackBar(const SnackBar(
          content: Text('다이아 50개 이상일 때 참가 신청을 할 수 있어요')));
      navigator.push(
        MaterialPageRoute(
          builder: (_) => DiamondRechargeScreen(currentDiamonds: diamonds),
        ),
      );
      return;
    }
    final isFirstCome = meeting.joinMethod == JoinMethod.firstCome;
    // 실제 참가/신청 전에 안내 화면을 띄우고, 동의해야 진행된다.
    final agreed = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            isFirstCome ? Notices.joinFirstCome() : Notices.joinApproval(),
      ),
    );
    if (agreed != true) return;
    if (isFirstCome) {
      // 선착순: 즉시 확정 → 채팅 탭(2번째)의 채팅방으로 이동
      selectedTab.value = 1;
    } else {
      // 승인제: 참가 신청 완료 → 내모임 탭(3번째)으로 이동
      selectedTab.value = 2;
      messenger.showSnackBar(
          const SnackBar(content: Text('참가 신청이 완료되었습니다')));
    }
    navigator.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final participants = repository.participantsOf(meeting);
    final dateTime =
        DateFormat('y년 M월 d일 (E) HH:mm', 'ko_KR').format(meeting.startTime);
    final spots = meeting.spotsLeft;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Icon(Icons.share_rounded, color: AppColors.textSecondary),
          SizedBox(width: 12),
          Icon(Icons.flag_rounded, color: AppColors.textSecondary),
          SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(
            children: [
              _categoryChip(),
              const SizedBox(width: 8),
              _statusBadge(meeting.isFull),
              const SizedBox(width: 8),
              _joinBadge(meeting.joinMethod),
            ],
          ),
          const SizedBox(height: 12),
          Text(meeting.title,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _infoRow(Icons.schedule_rounded, dateTime),
          _infoRow(Icons.location_on_rounded, meeting.placeLabel),
          _infoRow(Icons.payments_rounded, meeting.cost.display),
          _infoRow(Icons.people_rounded,
              '${meeting.currentMembers}/${meeting.maxMembers}명 · ${spots > 0 ? '$spots자리 남음' : '마감'}'),
          const SizedBox(height: 16),
          Text(meeting.description,
              style: const TextStyle(
                  fontSize: 14, height: 1.5, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          const Divider(color: AppColors.borderTertiary, height: 1),
          const SizedBox(height: 16),
          Text('참가자 ${participants.length}명',
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          for (var i = 0; i < participants.length; i++)
            ParticipantCard(member: participants[i], isHost: i == 0),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: AppColors.bgPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _onApply(context),
              child: Text(
                meeting.joinMethod == JoinMethod.firstCome
                    ? '모임 참가하기'
                    : '참가 신청하기',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(meeting.icon,
                size: 14, color: AppColors.textPrimary),
            const SizedBox(width: 4),
            Text(meeting.categoryLabel,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
          ],
        ),
      );

  Widget _statusBadge(bool full) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: full ? AppColors.bgTertiary : AppColors.bgSuccess,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(full ? '마감' : '모집중',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: full ? AppColors.textSecondary : AppColors.textSuccess)),
      );

  Widget _joinBadge(JoinMethod m) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(m.label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
      );

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary))),
          ],
        ),
      );
}
