import 'package:flutter/material.dart';
import '../../data/category_catalog.dart';
import '../../theme/app_colors.dart';
import 'signup_flow.dart';
import 'signup_locations_screen.dart';
import 'signup_scaffold.dart';
import 'signup_session.dart';

/// 관심 카테고리 다중 선택. [CategoryCatalog.groups] 를 그대로 재활용한다.
/// 최소 1개 선택 필요.
class SignupCategoriesScreen extends StatefulWidget {
  const SignupCategoriesScreen({super.key, required this.session});
  final SignupSession session;

  @override
  State<SignupCategoriesScreen> createState() =>
      _SignupCategoriesScreenState();
}

class _SignupCategoriesScreenState extends State<SignupCategoriesScreen> {
  Set<String> get _selected => widget.session.interestCategories;

  void _toggle(String label) {
    setState(() {
      if (!_selected.add(label)) _selected.remove(label);
    });
  }

  void _next() {
    Navigator.of(context).push(signupRoute(
      (_) => SignupLocationsScreen(session: widget.session),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final count = _selected.length;
    return SignupScaffold(
      step: 7,
      totalSteps: 9,
      title: '어떤 모임에 관심 있어요?',
      subtitle: '관심사에 맞춰 모임을 추천해드려요.\n끌리는 것 모두 골라 보세요.',
      primaryLabel: count == 0 ? '1개 이상 골라 주세요' : '$count개 선택 · 다음',
      onPrimary: count > 0 ? _next : null,
      bottomHint: const Text('가입 후 프로필에서 언제든 다시 고를 수 있어요.'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final group in CategoryCatalog.groups) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(group.icon, size: 16, color: AppColors.coral),
                const SizedBox(width: 6),
                Text(group.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    )),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in group.items)
                  _CategoryChip(
                    label: label,
                    selected: _selected.contains(label),
                    onTap: () => _toggle(label),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.textPrimary : AppColors.bgPrimary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  selected ? AppColors.textPrimary : AppColors.borderTertiary,
              width: selected ? 1.0 : 0.5,
            ),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary,
              )),
        ),
      ),
    );
  }
}
