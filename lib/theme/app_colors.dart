import 'package:flutter/material.dart';

/// 브랜드 가이드 v1(docs/app/브랜드-가이드.html) 컬러 토큰.
abstract final class AppColors {
  // 브랜드
  /// 주 컬러 — CTA, 액션, 선택 칩.
  static const coral = Color(0xFFEE7A4D);

  /// 보조 — 출석·진행·모임 신호.
  static const mint = Color(0xFF4FB286);

  /// 강조 — 햇살·하이라이트(소량).
  static const amber = Color(0xFFF4B740);

  /// 브랜드 칼라의 옅은 배경(칩·라벨용).
  static const bgCoral = Color(0xFFFCE6DC);
  static const bgMint = Color(0xFFE0F1E7);
  static const bgAmber = Color(0xFFFCEFD3);

  // 배경
  /// 외곽 배경(Scaffold).
  static const cream = Color(0xFFFAF6EE);

  /// 카드/표면.
  static const bgPrimary = Color(0xFFFFFFFF);

  /// 가벼운 영역(Subtle) — 입력칸·옅은 칩 배경.
  static const bgSecondary = Color(0xFFF4F1E8);

  /// 호환을 위해 유지(과거 코드가 bgTertiary를 참조함). bgSecondary와 동일 톤.
  static const bgTertiary = Color(0xFFF4F1E8);

  // 텍스트
  static const textPrimary = Color(0xFF2C2C2A);
  static const textSecondary = Color(0xFF5F5E5A);
  static const textTertiary = Color(0xFF888780);

  // 시맨틱 — 텍스트/아이콘
  /// 다이아·정보.
  static const textInfo = Color(0xFF185FA5);

  /// 정산·방장.
  static const textWarning = Color(0xFF854F0B);

  /// 출석·확정.
  static const textSuccess = Color(0xFF3B6D11);

  /// 차단·나가기.
  static const textDanger = Color(0xFFA32D2D);

  // 시맨틱 — 옅은 배경(카테고리 chip/badge용)
  static const bgInfo = Color(0xFFE6F1FB);
  static const bgWarning = Color(0xFFFAEEDA);
  static const bgSuccess = Color(0xFFEAF3DE);

  // 핑크(여성 멤버 아바타 등 — 유지)
  static const bgPink = Color(0xFFFDE7EF);
  static const textPink = Color(0xFFC2185B);

  // 보더 — 가이드: rgba(0,0,0,0.12)
  static const borderTertiary = Color(0x1F000000);
  static const borderInfo = Color(0xFFB5D4F4);
}
