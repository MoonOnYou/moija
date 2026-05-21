import 'package:flutter/material.dart';
import '../../../models/member.dart';
import '../../../theme/app_colors.dart';

class ParticipantCard extends StatelessWidget {
  const ParticipantCard({super.key, required this.member, this.isHost = false});

  final Member member;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    final initial =
        member.nickname.isNotEmpty ? member.nickname.substring(0, 1) : '?';
    final isMale = member.gender == Gender.male;
    final avatarBg = isMale ? AppColors.bgInfo : AppColors.bgPink;
    final avatarFg = isMale ? AppColors.textInfo : AppColors.textPink;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderTertiary, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: avatarBg, shape: BoxShape.circle),
            child: Text(initial,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: avatarFg)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(member.nickname,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    if (isHost) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                            color: AppColors.textInfo,
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('방장',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ],
                    const Spacer(),
                    const Icon(Icons.star, size: 13, color: Color(0xFFE6A700)),
                    const SizedBox(width: 2),
                    Text(member.mannerScore.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 2),
                Text('${member.birthYear}년생 · ${member.gender.label}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                    '활동 ${member.totalActivities}회 · 나와 ${member.timesMetWithMe}번 만남',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textTertiary)),
                const SizedBox(height: 4),
                Text(member.intro,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
