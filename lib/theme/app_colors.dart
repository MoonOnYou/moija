import 'package:flutter/material.dart';

/// 목업(docs/page/01_홈.html)의 CSS 변수에 대응하는 색상 토큰.
abstract final class AppColors {
  // 배경
  static const bgPrimary = Color(0xFFFFFFFF);
  static const bgSecondary = Color(0xFFF7F6F3);
  static const bgTertiary = Color(0xFFF1EFE8);
  static const bgInfo = Color(0xFFE6F1FB);
  static const bgWarning = Color(0xFFFAEEDA);
  static const bgSuccess = Color(0xFFEAF3DE);

  // 텍스트
  static const textPrimary = Color(0xFF2C2C2A);
  static const textSecondary = Color(0xFF5F5E5A);
  static const textTertiary = Color(0xFF888780);
  static const textInfo = Color(0xFF185FA5);
  static const textWarning = Color(0xFF854F0B);
  static const textSuccess = Color(0xFF3B6D11);
  static const textDanger = Color(0xFFA32D2D);

  // 보더
  static const borderTertiary = Color(0x26000000); // rgba(0,0,0,0.15)
  static const borderInfo = Color(0xFFB5D4F4);
}
