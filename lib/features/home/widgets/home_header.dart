import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.monthLabel,
    required this.diamonds,
    required this.onDiamondTap,
  });

  /// 예: "2026년 5월"
  final String monthLabel;
  final int diamonds;
  final VoidCallback onDiamondTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '모이자',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                monthLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            key: const Key('header-diamond'),
            onTap: onDiamondTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.bgInfo,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.diamond,
                      size: 15, color: AppColors.textInfo),
                  const SizedBox(width: 4),
                  Text(
                    '$diamonds',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textInfo,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          const Icon(Icons.notifications_none,
              size: 20, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
