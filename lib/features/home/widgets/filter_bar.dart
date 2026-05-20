import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// 홈 상단 필터 진입 바. 탭하면 필터 화면으로 이동. 활성 필터 개수를 배지로 표시.
class FilterBar extends StatelessWidget {
  const FilterBar({super.key, required this.activeCount, required this.onTap});

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('filter-bar'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.borderTertiary, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.filter_list, size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            const Text('필터',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            if (activeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.textInfo,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$activeCount',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            const Spacer(),
            const Text('카테고리 · 장소 · 시간',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
