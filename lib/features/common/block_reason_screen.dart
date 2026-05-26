import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 차단 전에 사유를 받는 풀스크린.
/// 확정 시 사유 문자열을 pop으로 반환(취소는 null).
class BlockReasonScreen extends StatefulWidget {
  const BlockReasonScreen({super.key, required this.targetName});

  /// 차단 대상의 닉네임(헤더에 노출).
  final String targetName;

  /// 헬퍼: push → 사유 문자열 또는 null. context는 이 호출 시점에 mounted여야 한다.
  static Future<String?> show(BuildContext context, String targetName) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => BlockReasonScreen(targetName: targetName),
      ),
    );
  }

  @override
  State<BlockReasonScreen> createState() => _BlockReasonScreenState();
}

class _BlockReasonScreenState extends State<BlockReasonScreen> {
  final _controller = TextEditingController();
  String? _selectedPreset;

  static const _presets = <String>[
    '욕설·폭언',
    '도배·광고',
    '약속 어김(노쇼)',
    '음주·불쾌한 행동',
    '기타',
  ];

  bool get _canSubmit =>
      _selectedPreset != null || _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('차단 사유 메모'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text('${widget.targetName}님을 차단할까요?',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.35)),
          const SizedBox(height: 8),
          const Text(
            '차단한 상대는 내 프로필·모임을 볼 수 없고\n메시지도 더 이상 받지 않아요.',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5),
          ),
          const SizedBox(height: 24),
          const Text('사유 선택',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _presets)
                _PresetChip(
                  label: p,
                  selected: _selectedPreset == p,
                  onTap: () => setState(() =>
                      _selectedPreset = _selectedPreset == p ? null : p),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('자세한 사유 (선택)',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary)),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            minLines: 4,
            maxLines: 8,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: '있었던 일을 적어주세요. 운영팀 신고 처리에 참고돼요.',
              hintStyle: const TextStyle(
                  fontSize: 13, color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.bgSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.borderTertiary, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.textPrimary, width: 1.4),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _canSubmit
                  ? () {
                      final reason = [
                        ?_selectedPreset,
                        if (_controller.text.trim().isNotEmpty)
                          _controller.text.trim(),
                      ].join(' · ');
                      Navigator.of(context).pop(reason);
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.textDanger,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.bgTertiary,
                disabledForegroundColor: AppColors.textTertiary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              child: const Text('차단하기'),
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
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
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color:
                selected ? AppColors.textPrimary : AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.textPrimary
                  : AppColors.borderTertiary,
              width: selected ? 1.0 : 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_rounded,
                    size: 14, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : AppColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
