import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 브랜드 가이드의 "모임 허들" 로고 — 3개 점이 옹기종기.
/// 외부 자산(PNG/SVG) 없이 CustomPaint로 그려서 어느 곳에서나 일관 노출.
class MoijaLogo extends StatelessWidget {
  const MoijaLogo({super.key, this.size = 32, this.showBackground = true});

  final double size;

  /// 둥근 사각형 배경을 그릴지 여부. AppBar 등 좁은 자리엔 false로.
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MoijaLogoPainter(showBackground: showBackground),
      ),
    );
  }
}

class _MoijaLogoPainter extends CustomPainter {
  const _MoijaLogoPainter({required this.showBackground});

  final bool showBackground;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 64.0;
    if (showBackground) {
      final bg = Paint()..color = const Color(0xFFFFF3E0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(16 * scale),
        ),
        bg,
      );
    }
    canvas.drawCircle(
      Offset(25 * scale, 38 * scale),
      12 * scale,
      Paint()..color = AppColors.coral,
    );
    canvas.drawCircle(
      Offset(40 * scale, 38 * scale),
      12 * scale,
      Paint()..color = AppColors.mint,
    );
    canvas.drawCircle(
      Offset(32 * scale, 26 * scale),
      11 * scale,
      Paint()..color = AppColors.amber,
    );
  }

  @override
  bool shouldRepaint(_MoijaLogoPainter old) =>
      old.showBackground != showBackground;
}
