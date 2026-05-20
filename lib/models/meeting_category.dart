import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 모임 카테고리. 칩/아이콘/색상 정보를 함께 갖는다.
enum MeetingCategory {
  escapeRoom('방탈출', Icons.vpn_key, AppColors.bgInfo, AppColors.textInfo),
  bowling('볼링', Icons.sports_handball, AppColors.bgInfo, AppColors.textInfo);

  const MeetingCategory(
    this.label,
    this.icon,
    this.chipBackground,
    this.chipForeground,
  );

  final String label;
  final IconData icon;
  final Color chipBackground;
  final Color chipForeground;
}
