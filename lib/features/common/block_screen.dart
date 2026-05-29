import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 차단 화면. 나만 볼 수 있는 메모만 간단히 받는다.
/// 확정 시 메모 문자열(빈 문자열 가능)을 pop으로 반환, 취소는 null.
class BlockScreen extends StatefulWidget {
  const BlockScreen({super.key, required this.targetName});

  /// 차단 대상 닉네임(헤더에 노출).
  final String targetName;

  static Future<String?> show(BuildContext context, String targetName) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => BlockScreen(targetName: targetName),
      ),
    );
  }

  @override
  State<BlockScreen> createState() => _BlockScreenState();
}

class _BlockScreenState extends State<BlockScreen> {
  final _controller = TextEditingController();

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
        title: const Text('차단하기',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
                color: AppColors.bgSecondary, shape: BoxShape.circle),
            child: const Icon(Icons.block_rounded,
                color: AppColors.textPrimary, size: 26),
          ),
          const SizedBox(height: 16),
          Text('${widget.targetName}님을 차단할까요?',
              style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 8),
          const Text(
            '차단한 상대는 내 프로필·모임을 볼 수 없고\n같은 모임·채팅에도 함께 나타나지 않아요.',
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const _SectionLabel('메모'),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        size: 11, color: AppColors.textTertiary),
                    SizedBox(width: 3),
                    Text('나만 볼 수 있어요',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            maxLength: 200,
            style: const TextStyle(fontSize: 14, height: 1.5),
            decoration: InputDecoration(
              hintText: '왜 차단하는지 적어두면 나중에 기억하기 좋아요. (선택)',
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
                borderSide:
                    const BorderSide(color: AppColors.textPrimary, width: 1.4),
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
            height: 52,
            child: FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(_controller.text.trim()),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.textDanger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              child: const Text('차단하기'),
            ),
          ),
        ),
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
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textTertiary));
  }
}
