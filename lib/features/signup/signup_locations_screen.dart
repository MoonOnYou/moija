import 'package:flutter/material.dart';
import '../../data/location_catalog.dart';
import '../../theme/app_colors.dart';
import '../filter/location_picker_screen.dart';
import 'signup_complete_screen.dart';
import 'signup_flow.dart';
import 'signup_scaffold.dart';
import 'signup_session.dart';

/// 관심 동네 선택. 기존 [LocationPickerScreen]을 그대로 띄우고, 결과를 세션에 저장.
/// 선택된 동네는 카드로, 하단의 + 추가하기로 더 고를 수 있다.
class SignupLocationsScreen extends StatefulWidget {
  const SignupLocationsScreen({super.key, required this.session});
  final SignupSession session;

  @override
  State<SignupLocationsScreen> createState() =>
      _SignupLocationsScreenState();
}

class _SignupLocationsScreenState extends State<SignupLocationsScreen> {
  Set<String> get _selected => widget.session.interestLocations;

  Future<void> _pickMore() async {
    final picked = await Navigator.of(context).push<Set<String>>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initial: _selected,
          singleSelect: false,
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _selected
          ..clear()
          ..addAll(picked);
      });
    }
  }

  void _remove(String id) {
    setState(() => _selected.remove(id));
  }

  void _next() {
    Navigator.of(context).pushReplacement(signupRoute(
      (_) => SignupCompleteScreen(session: widget.session),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ids = _selected.toList();
    final count = ids.length;
    return SignupScaffold(
      step: 8,
      totalSteps: 8,
      title: '주로 어디서 만나요?',
      subtitle: '관심 동네에서 열리는 모임을 먼저 보여드려요.\n노선·지역 단위로도 고를 수 있어요.',
      primaryLabel: count == 0 ? '1개 이상 골라 주세요' : '$count곳 선택 · 완료',
      onPrimary: count > 0 ? _next : null,
      bottomHint:
          const Text('지하철 노선·시·군 단위까지 자세히 고를 수 있어요.'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final id in ids) _selectedRow(id),
          _addRow(empty: ids.isEmpty),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.bgMint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.textSuccess),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '동네는 가입 후 프로필에서 바꿀 수 있어요.\n오늘 위치는 추적하지 않아요.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.55,
                      color: AppColors.textSuccess,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedRow(String id) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.borderTertiary, width: 0.6),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.bgCoral,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.place_rounded,
                  size: 16, color: AppColors.coral),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                LocationCatalog.displayLabel(id),
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.textTertiary),
              onPressed: () => _remove(id),
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _addRow({required bool empty}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: _pickMore,
        borderRadius: BorderRadius.circular(14),
        child: DottedBorderCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppColors.bgPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded,
                      size: 18, color: AppColors.coral),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    empty ? '관심 동네 추가하기' : '동네 더 추가하기',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.coral,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Text('선택',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.coral)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 추가하기 행에만 쓰는 옅은 점선 카드. 선택된 동네 카드와 시각적으로 구분.
class DottedBorderCard extends StatelessWidget {
  const DottedBorderCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCoral.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.coral.withValues(alpha: 0.55)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      const Radius.circular(14),
    );
    final path = Path()..addRRect(rrect);

    const dashWidth = 4.0;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}
