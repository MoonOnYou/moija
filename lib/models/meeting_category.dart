import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 모임 카테고리. 칩/아이콘/색상 정보를 함께 갖는다.
enum MeetingCategory {
  restaurant('맛집', Icons.restaurant_rounded, AppColors.bgWarning, AppColors.textWarning),
  drink('술한잔', Icons.local_bar_rounded, AppColors.bgWarning, AppColors.textWarning),
  cafe('카페', Icons.local_cafe_rounded, AppColors.bgWarning, AppColors.textWarning),
  boardGame('보드게임', Icons.casino_rounded, AppColors.bgSuccess, AppColors.textSuccess),
  escapeRoom('방탈출', Icons.vpn_key_rounded, AppColors.bgInfo, AppColors.textInfo),
  karaoke('노래방', Icons.mic_rounded, AppColors.bgWarning, AppColors.textWarning),
  billiards('당구', Icons.sports_handball_rounded, AppColors.bgInfo, AppColors.textInfo),
  bowling('볼링', Icons.sports_handball_rounded, AppColors.bgInfo, AppColors.textInfo),
  climbing('클라이밍', Icons.landscape_rounded, AppColors.bgSuccess, AppColors.textSuccess),
  hiking('등산', Icons.terrain_rounded, AppColors.bgSuccess, AppColors.textSuccess),
  running('러닝', Icons.directions_run_rounded, AppColors.bgSuccess, AppColors.textSuccess),
  movie('영화', Icons.movie_rounded, AppColors.bgInfo, AppColors.textInfo),
  swimming('수영', Icons.pool_rounded, AppColors.bgSuccess, AppColors.textSuccess),
  lol('롤', Icons.sports_esports_rounded, AppColors.bgInfo, AppColors.textInfo),
  etc('기타', Icons.more_horiz_rounded, AppColors.bgTertiary, AppColors.textSecondary);

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
