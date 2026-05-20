import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 다이아 충전(플레이스홀더). 실제 결제는 범위 밖.
class DiamondRechargeScreen extends StatelessWidget {
  const DiamondRechargeScreen({super.key, required this.currentDiamonds});

  final int currentDiamonds;

  static const _options = [
    (50, 1100),
    (120, 2500),
    (300, 5900),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: const Text('다이아 충전'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgInfo,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.diamond, size: 18, color: AppColors.textInfo),
                const SizedBox(width: 8),
                Text('보유 다이아 $currentDiamonds개',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textInfo)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('충전 상품',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          for (final (amount, won) in _options)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderTertiary, width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.diamond, size: 18, color: AppColors.textInfo),
                  const SizedBox(width: 8),
                  Text('다이아 $amount개',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text('₩$won',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
