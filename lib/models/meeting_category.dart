import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 모임 카테고리. 칩/아이콘/색상 정보를 함께 갖는다.
enum MeetingCategory {
  escapeRoom('방탈출', Icons.vpn_key, AppColors.bgInfo, AppColors.textInfo),
  bowling('볼링', Icons.sports_handball, AppColors.bgInfo, AppColors.textInfo),
  karaoke('노래방', Icons.mic, AppColors.bgWarning, AppColors.textWarning),
  drink('술 한잔', Icons.local_bar, AppColors.bgWarning, AppColors.textWarning),
  cafe('카페', Icons.local_cafe, AppColors.bgWarning, AppColors.textWarning),
  hiking('등산', Icons.terrain, AppColors.bgSuccess, AppColors.textSuccess),
  swimming('수영', Icons.pool, AppColors.bgSuccess, AppColors.textSuccess),
  boardGame('보드게임', Icons.casino, AppColors.bgSuccess, AppColors.textSuccess),
  lol('롤', Icons.sports_esports, AppColors.bgInfo, AppColors.textInfo),
  etc('기타', Icons.more_horiz, AppColors.bgTertiary, AppColors.textSecondary);

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
