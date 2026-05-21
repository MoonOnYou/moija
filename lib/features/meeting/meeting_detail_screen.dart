import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/meeting_repository.dart';
import '../../data/wallet.dart';
import '../../models/meeting.dart';
import '../../theme/app_colors.dart';
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

  void _onApply(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    if (diamonds <= 50) {
      messenger.showSnackBar(const SnackBar(
          content: Text('다이아 50개 이상일 때 참가 신청을 할 수 있어요')));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DiamondRechargeScreen(currentDiamonds: diamonds),
        ),
      );
    } else {
      messenger.showSnackBar(
          const SnackBar(content: Text('참가 신청이 완료됐어요')));
      Navigator.pop(context);
    }
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Icon(Icons.share_outlined, color: AppColors.textSecondary),
          SizedBox(width: 12),
          Icon(Icons.flag_outlined, color: AppColors.textSecondary),
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
            ],
          ),
          const SizedBox(height: 12),
          Text(meeting.title,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _infoRow(Icons.schedule, dateTime),
          _infoRow(Icons.location_on_outlined,
              '${meeting.nearestStation} · ${meeting.location}'),
          _infoRow(Icons.payments_outlined, meeting.cost.display),
          _infoRow(Icons.people_outline,
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
                backgroundColor: AppColors.textPrimary,
                foregroundColor: AppColors.bgPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _onApply(context),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('참가 신청하기',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text('방장 수락 시 다이아 50개 차감',
                      style: TextStyle(fontSize: 11, color: Colors.white70)),
                ],
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
            color: meeting.category.chipBackground,
            borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(meeting.category.icon,
                size: 14, color: meeting.category.chipForeground),
            const SizedBox(width: 4),
            Text(meeting.categoryLabel,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: meeting.category.chipForeground)),
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
