import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 신고 화면의 확정 결과. [reason]은 "사유 · 상세" 형태, [alsoBlock]은 차단 동반 여부.
class ReportResult {
  const ReportResult({required this.reason, required this.alsoBlock});

  final String reason;
  final bool alsoBlock;
}

/// 사용자 신고 화면. 사유(프리셋) + 자세한 내용을 받아 운영팀에 전달한다.
/// 확정 시 [ReportResult]를 pop으로 반환(취소는 null).
class ReportScreen extends StatefulWidget {
  const ReportScreen({
    super.key,
    required this.targetName,
    this.allowAlsoBlock = true,
  });

  /// 신고 대상 닉네임(헤더에 노출).
  final String targetName;

  /// "차단도 같이하기" 옵션 노출 여부. 이미 차단된 상대(차단 목록)에서는 false.
  final bool allowAlsoBlock;

  static Future<ReportResult?> show(
    BuildContext context,
    String targetName, {
    bool allowAlsoBlock = true,
  }) {
    return Navigator.of(context).push<ReportResult>(
      MaterialPageRoute(
        builder: (_) => ReportScreen(
          targetName: targetName,
          allowAlsoBlock: allowAlsoBlock,
        ),
      ),
    );
  }

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _controller = TextEditingController();
  String? _selected;
  bool _alsoBlock = false;

  static const _presets = <String>[
    '욕설·폭언',
    '성희롱·불쾌한 언행',
    '사기·금전 문제',
    '도배·광고',
    '약속 어김(노쇼)',
    '기타',
  ];

  bool get _canSubmit => _selected != null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('신고하기',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _Header(
            iconBg: AppColors.bgCoral,
            iconColor: AppColors.textDanger,
            icon: Icons.flag_rounded,
            title: '${widget.targetName}님을 신고할까요?',
            subtitle: '신고 내용은 운영팀이 검토해요.\n신고자 정보는 상대에게 공개되지 않아요.',
          ),
          const SizedBox(height: 24),
          const _SectionLabel('신고 사유'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _presets)
                _SelectChip(
                  label: p,
                  selected: _selected == p,
                  onTap: () =>
                      setState(() => _selected = _selected == p ? null : p),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionLabel('자세한 내용 (선택)'),
          const SizedBox(height: 10),
          _MemoField(
            controller: _controller,
            hint: '있었던 일을 적어주세요. 운영팀 검토에 참고돼요.',
            onChanged: () => setState(() {}),
          ),
          if (widget.allowAlsoBlock) ...[
            const SizedBox(height: 20),
            _AlsoBlockToggle(
              value: _alsoBlock,
              onChanged: (v) => setState(() => _alsoBlock = v),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _canSubmit
                  ? () {
                      final reason = [
                        ?_selected,
                        if (_controller.text.trim().isNotEmpty)
                          _controller.text.trim(),
                      ].join(' · ');
                      Navigator.of(context).pop(ReportResult(
                        reason: reason,
                        alsoBlock: widget.allowAlsoBlock && _alsoBlock,
                      ));
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.textDanger,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.bgTertiary,
                disabledForegroundColor: AppColors.textTertiary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              child: const Text('신고하기'),
            ),
          ),
        ),
      ),
    );
  }
}

/// 신고/차단 화면 공통 헤더(아이콘 + 제목 + 부제).
class _Header extends StatelessWidget {
  const _Header({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 26),
        ),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(
                fontSize: 19, fontWeight: FontWeight.w700, height: 1.3)),
        const SizedBox(height: 8),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
      ],
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
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textTertiary));
  }
}

class _MemoField extends StatelessWidget {
  const _MemoField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      minLines: 4,
      maxLines: 8,
      maxLength: 300,
      style: const TextStyle(fontSize: 14, height: 1.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(fontSize: 13, color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.bgSecondary,
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
          borderSide: const BorderSide(color: AppColors.textPrimary, width: 1.4),
        ),
      ),
    );
  }
}

/// "차단도 같이하기" 토글. 켜면 신고와 동시에 상대를 차단한다.
class _AlsoBlockToggle extends StatelessWidget {
  const _AlsoBlockToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          decoration: BoxDecoration(
            color: value ? AppColors.bgCoral : AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value ? AppColors.textDanger : AppColors.borderTertiary,
              width: value ? 1.0 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.block_rounded,
                  size: 18,
                  color:
                      value ? AppColors.textDanger : AppColors.textTertiary),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('차단도 같이하기',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('신고와 함께 이 사용자를 차단해요',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.textDanger,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  const _SelectChip({
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
            color: selected ? AppColors.textPrimary : AppColors.bgSecondary,
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
                  color: selected ? Colors.white : AppColors.textPrimary)),
        ),
      ),
    );
  }
}
