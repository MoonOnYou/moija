import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'withdrawal_confirm_screen.dart';
import 'withdrawal_flow.dart';

/// 1단계 — 떠나는 이유(선택). 운영 인사이트용이며 선택사항이라 건너뛰어도 된다.
class WithdrawalReasonScreen extends StatefulWidget {
  const WithdrawalReasonScreen({super.key, required this.session});
  final WithdrawalSession session;

  @override
  State<WithdrawalReasonScreen> createState() => _WithdrawalReasonScreenState();
}

class _WithdrawalReasonScreenState extends State<WithdrawalReasonScreen> {
  static const List<String> _reasons = [
    '동네 모임이 별로 없어요',
    '사용이 어려워요',
    '알림이 너무 많아요',
    '부적절한 사용자가 있어요',
    '개인정보가 걱정돼요',
    '기타',
  ];

  final TextEditingController _detail = TextEditingController();
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.session.reasons);
    _detail.text = widget.session.detail;
  }

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  void _next() {
    widget.session.reasons
      ..clear()
      ..addAll(_selected);
    widget.session.detail = _detail.text.trim();
    Navigator.of(context).push(withdrawalRoute(
      (_) => WithdrawalConfirmScreen(session: widget.session),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return WithdrawalScaffold(
      appBarTitle: '회원 탈퇴',
      heading: '떠나는 이유를 알려주세요',
      subtitle: const Text('해당하는 항목을 모두 선택해 주세요. 더 나은 모이자를 만드는 데 도움이 돼요.'),
      actions: [
        WithdrawalButton.primary(
          label: '다음',
          onPressed: _selected.isEmpty ? null : _next,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final reason in _reasons)
            _ReasonTile(
              label: reason,
              selected: _selected.contains(reason),
              onTap: () => setState(
                () => _selected.contains(reason)
                    ? _selected.remove(reason)
                    : _selected.add(reason),
              ),
            ),
          const SizedBox(height: 14),
          TextField(
            controller: _detail,
            minLines: 2,
            maxLines: 4,
            maxLength: 200,
            style: const TextStyle(fontSize: 13.5, height: 1.5),
            decoration: InputDecoration(
              hintText: '자세한 내용 (선택)',
              hintStyle: const TextStyle(
                  fontSize: 13.5, color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.bgSecondary,
              counterText: '',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.coral, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 체크박스 한 줄(둥근 사각 마커 + 라벨). 복수 선택용. 가는 하단 구분선.
class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.borderTertiary, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? AppColors.coral : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected ? AppColors.coral : const Color(0xFFD4D2C9),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Center(
                      child: Icon(Icons.check_rounded,
                          size: 13, color: Colors.white))
                  : null,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}
