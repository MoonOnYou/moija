import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/meeting.dart';
import '../../../theme/app_colors.dart';

class MeetingCard extends StatelessWidget {
  const MeetingCard({super.key, required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(meeting.startTime);
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: meeting.category.chipBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(meeting.category.icon,
                size: 28, color: meeting.category.chipForeground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meeting.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(time,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    const Text('  ·  ',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(meeting.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${meeting.currentMembers} / ${meeting.maxMembers}명 · ${_spotsLabel(meeting.spotsLeft)}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textInfo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _spotsLabel(int spots) =>
      spots > 0 ? '$spots자리 남음' : '마감';
}
