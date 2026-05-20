import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';

class SelectedDaySummary extends StatelessWidget {
  const SelectedDaySummary({
    super.key,
    required this.selectedDay,
    required this.meetingCount,
    required this.filterCount,
  });

  final DateTime selectedDay;
  final int meetingCount;
  final int filterCount;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        DateFormat('M월 d일 (E)', 'ko_KR').format(selectedDay);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderTertiary, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateLabel,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text('필터 $filterCount개 · 모임 $meetingCount개',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
