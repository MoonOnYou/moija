import 'package:flutter/material.dart';
import '../../models/member.dart';
import '../../theme/app_colors.dart';
import 'signup_categories_screen.dart';
import 'signup_flow.dart';
import 'signup_scaffold.dart';
import 'signup_session.dart';

/// 성별 + 출생년도. 만 14세 미만은 가입 불가, 허위 입력에 대한 경고를 강조.
class SignupProfileScreen extends StatefulWidget {
  const SignupProfileScreen({super.key, required this.session});
  final SignupSession session;

  @override
  State<SignupProfileScreen> createState() => _SignupProfileScreenState();
}

class _SignupProfileScreenState extends State<SignupProfileScreen> {
  late Gender? _gender = widget.session.gender;
  late int? _birthYear = widget.session.birthYear;

  static const int _today = 2026;
  static const int _minAge = 14;
  static const int _maxAge = 99;
  int get _maxYear => _today - _minAge; // 2012
  int get _minYear => _today - _maxAge; // 1927

  bool get _underAge {
    if (_birthYear == null) return false;
    return _birthYear! > _maxYear;
  }

  bool get _valid => _gender != null && _birthYear != null && !_underAge;

  Future<void> _pickYear() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _YearPickerSheet(
        initial: _birthYear ?? _maxYear,
        minYear: _minYear,
        maxYear: _today, // 보여주기는 오늘까지, 미성년 안내는 본문에서 한다.
      ),
    );
    if (picked != null) {
      setState(() => _birthYear = picked);
    }
  }

  void _next() {
    widget.session.gender = _gender;
    widget.session.birthYear = _birthYear;
    Navigator.of(context).push(signupRoute(
      (_) => SignupCategoriesScreen(session: widget.session),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SignupScaffold(
      step: 5,
      totalSteps: 7,
      title: '나에 대해 알려 주세요',
      subtitle: '성별·나이는 모임 추천과 같은 또래 매칭에만 쓰여요.',
      primaryLabel: '다음',
      onPrimary: _valid ? _next : null,
      bottomHint: const Text('만 14세 미만은 안전을 위해 가입할 수 없어요.'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('성별'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _GenderTile(
                  label: '여성',
                  icon: Icons.female_rounded,
                  selected: _gender == Gender.female,
                  selectedColor: AppColors.textPink,
                  selectedBg: AppColors.bgPink,
                  onTap: () => setState(() => _gender = Gender.female),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GenderTile(
                  label: '남성',
                  icon: Icons.male_rounded,
                  selected: _gender == Gender.male,
                  selectedColor: AppColors.textInfo,
                  selectedBg: AppColors.bgInfo,
                  onTap: () => setState(() => _gender = Gender.male),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const _SectionLabel('출생년도'),
          const SizedBox(height: 10),
          InkWell(
            onTap: _pickYear,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _underAge
                        ? AppColors.textDanger
                        : AppColors.borderTertiary,
                    width: _underAge ? 1.0 : 0.6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _birthYear == null
                          ? '출생년도를 선택해 주세요'
                          : '$_birthYear년',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _birthYear == null
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (_birthYear != null && !_underAge)
                    Text(
                      '만 ${_today - _birthYear!}세',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary),
                    )
                  else
                    const Icon(Icons.expand_more_rounded,
                        color: AppColors.textTertiary, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_underAge)
            Row(
              children: const [
                Icon(Icons.error_outline_rounded,
                    size: 14, color: AppColors.textDanger),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '만 14세 미만은 가입할 수 없어요.',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDanger),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 22),
          const _WarningCard(),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ));
  }
}

class _GenderTile extends StatelessWidget {
  const _GenderTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.selectedBg,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final Color selectedBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: selected ? selectedBg : AppColors.bgPrimary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? selectedColor : AppColors.borderTertiary,
              width: selected ? 1.4 : 0.6,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 28,
                  color: selected
                      ? selectedColor
                      : AppColors.textTertiary),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? selectedColor
                        : AppColors.textPrimary,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.bgWarning,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: AppColors.textWarning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '거짓으로 입력하면 안 돼요\n허위 성별·나이가 발견되면 모임 참여가 제한되거나\n계정이 영구 정지될 수 있어요.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.6,
                color: AppColors.textWarning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YearPickerSheet extends StatefulWidget {
  const _YearPickerSheet({
    required this.initial,
    required this.minYear,
    required this.maxYear,
  });
  final int initial;
  final int minYear;
  final int maxYear;

  @override
  State<_YearPickerSheet> createState() => _YearPickerSheetState();
}

class _YearPickerSheetState extends State<_YearPickerSheet> {
  late int _value = widget.initial.clamp(widget.minYear, widget.maxYear);
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: widget.maxYear - _value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 최신 연도가 위로 오도록 max → min 순서로 정렬한다.
    final years = List.generate(
        widget.maxYear - widget.minYear + 1, (i) => widget.maxYear - i);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          const Text('출생년도를 선택해 주세요',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Center(
                    child: Container(
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                ListWheelScrollView.useDelegate(
                  controller: _controller,
                  itemExtent: 44,
                  perspective: 0.003,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (i) =>
                      setState(() => _value = years[i]),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: years.length,
                    builder: (_, i) {
                      final y = years[i];
                      final selected = y == _value;
                      return Center(
                        child: Text('$y년',
                            style: TextStyle(
                              fontSize: selected ? 20 : 16,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                            )),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
              onPressed: () => Navigator.of(context).pop(_value),
              child: const Text('선택 완료'),
            ),
          ),
        ],
      ),
    );
  }
}
