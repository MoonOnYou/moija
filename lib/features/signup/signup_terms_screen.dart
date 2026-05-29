import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'signup_flow.dart';
import 'signup_phone_screen.dart';
import 'signup_scaffold.dart';
import 'signup_session.dart';

/// 약관 동의 (필수 4 + 선택 1). 심사 리젝되지 않게 명확히 분리한다.
class SignupTermsScreen extends StatefulWidget {
  const SignupTermsScreen({super.key, required this.session});
  final SignupSession session;

  @override
  State<SignupTermsScreen> createState() => _SignupTermsScreenState();
}

class _SignupTermsScreenState extends State<SignupTermsScreen> {
  late final List<_TermItem> _items = [
    _TermItem(
      key: 'age',
      label: '만 14세 이상입니다',
      required: true,
      getter: () => widget.session.agreedAge,
      setter: (v) => widget.session.agreedAge = v,
    ),
    _TermItem(
      key: 'service',
      label: '서비스 이용약관 동의',
      required: true,
      getter: () => widget.session.agreedService,
      setter: (v) => widget.session.agreedService = v,
    ),
    _TermItem(
      key: 'privacy',
      label: '개인정보 수집·이용 동의',
      required: true,
      getter: () => widget.session.agreedPrivacy,
      setter: (v) => widget.session.agreedPrivacy = v,
    ),
    _TermItem(
      key: 'location',
      label: '위치기반서비스 이용 동의',
      required: true,
      getter: () => widget.session.agreedLocation,
      setter: (v) => widget.session.agreedLocation = v,
    ),
    _TermItem(
      key: 'marketing',
      label: '이벤트·혜택 알림 받기',
      required: false,
      getter: () => widget.session.agreedMarketing,
      setter: (v) => widget.session.agreedMarketing = v,
    ),
  ];

  bool get _allOn => _items.every((e) => e.getter());
  bool get _requiredAllOn =>
      _items.where((e) => e.required).every((e) => e.getter());

  void _setAll(bool v) {
    setState(() {
      for (final e in _items) {
        e.setter(v);
      }
    });
  }

  void _toggle(_TermItem e) {
    setState(() => e.setter(!e.getter()));
  }

  void _showDetail(_TermItem e) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgPrimary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TermsSheet(label: e.label),
    );
  }

  void _next() {
    Navigator.of(
      context,
    ).push(signupRoute((_) => SignupPhoneScreen(session: widget.session)));
  }

  @override
  Widget build(BuildContext context) {
    return SignupScaffold(
      step: 1,
      totalSteps: 7,
      title: '먼저 약관에 동의해 주세요',
      subtitle: '꼭 필요한 항목만 받아요. 선택은 언제든 끌 수 있어요.',
      primaryLabel: '동의하고 다음',
      onPrimary: _requiredAllOn ? _next : null,
      bottomHint: const Text('필수 항목 4개에 동의해야 가입을 진행할 수 있어요.'),
      child: Column(
        children: [
          _AllAgreeRow(on: _allOn, onChanged: () => _setAll(!_allOn)),
          const SizedBox(height: 6),
          for (final item in _items)
            _TermRow(
              item: item,
              onTap: () => _toggle(item),
              onDetail: () => _showDetail(item),
            ),
        ],
      ),
    );
  }
}

class _TermItem {
  _TermItem({
    required this.key,
    required this.label,
    required this.required,
    required this.getter,
    required this.setter,
  });
  final String key;
  final String label;
  final bool required;
  final bool Function() getter;
  final void Function(bool) setter;
}

class _AllAgreeRow extends StatelessWidget {
  const _AllAgreeRow({required this.on, required this.onChanged});
  final bool on;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 6, 14),
        child: Row(
          children: [
            _Check(on: on, big: true),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '전체 동의 (선택 항목 포함)',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermRow extends StatelessWidget {
  const _TermRow({
    required this.item,
    required this.onTap,
    required this.onDetail,
  });

  final _TermItem item;
  final VoidCallback onTap;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final on = item.getter();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 12, 6, 12),
        child: Row(
          children: [
            _Check(on: on),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Text(
                    item.required ? '[필수] ' : '[선택] ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: item.required
                          ? AppColors.coral
                          : AppColors.textTertiary,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (item.key != 'age')
              TextButton(
                onPressed: onDetail,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textTertiary,
                  minimumSize: const Size(40, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Text('보기 ›'),
              )
            else
              const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.on, this.big = false});
  final bool on;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final size = big ? 22.0 : 20.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: on ? AppColors.coral : AppColors.bgPrimary,
        shape: BoxShape.circle,
        border: Border.all(
          color: on ? AppColors.coral : AppColors.borderTertiary,
          width: 1.2,
        ),
      ),
      child: Icon(
        Icons.check_rounded,
        size: big ? 15 : 13,
        color: on ? Colors.white : AppColors.textTertiary,
      ),
    );
  }
}

class _TermsSheet extends StatelessWidget {
  const _TermsSheet({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: const Text(
                    '본 약관은 모이자 서비스 이용에 관한 권리와 의무, 책임 사항 등을 정합니다.\n\n'
                    '제1조(목적) 본 약관은 회사가 제공하는 서비스의 이용 조건을 규정하기 위한 것입니다.\n\n'
                    '제2조(정의) "회원"이라 함은 본 약관에 동의하고 서비스를 이용하는 자를 말합니다.\n\n'
                    '제3조(약관의 효력) 본 약관은 회원이 동의함과 동시에 효력이 발생합니다.\n\n'
                    '※ 실제 약관 전문은 서비스 출시 시 제공됩니다.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.65,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
