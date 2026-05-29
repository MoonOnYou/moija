import 'package:flutter/material.dart';
import '../../models/member.dart';
import '../../theme/app_colors.dart';
import '../common/report_screen.dart';

/// 차단한 사용자 목록 (docs/page/15_차단목록.html 참고).
/// 차단 해제 시 목록에서 제거된다. mock 데이터.
class BlockListScreen extends StatefulWidget {
  const BlockListScreen({super.key});

  @override
  State<BlockListScreen> createState() => _BlockListScreenState();
}

class _BlockedUser {
  const _BlockedUser({
    required this.name,
    required this.date,
    required this.gender,
    this.memo = '',
  });

  final String name;
  final String date;
  final Gender gender;
  final String memo;

  Color get avatarBg =>
      gender == Gender.male ? AppColors.bgInfo : AppColors.bgPink;
  Color get avatarFg =>
      gender == Gender.male ? AppColors.textInfo : AppColors.textPink;
}

class _BlockListScreenState extends State<BlockListScreen> {
  late final List<_BlockedUser> _users = [
    const _BlockedUser(
      name: '방탈마스터',
      date: '2026.05.20',
      gender: Gender.male,
      memo: '모임에서 무례했어요. 자꾸 시간 안 지킴.',
    ),
    const _BlockedUser(
      name: 'jin_92',
      date: '2026.05.12',
      gender: Gender.male,
      memo: '정산하고 돈 안 줬음. 조심.',
    ),
    const _BlockedUser(
      name: '수영러버',
      date: '2026.04.30',
      gender: Gender.female,
    ),
    const _BlockedUser(
      name: '등산왕김씨',
      date: '2026.04.22',
      gender: Gender.male,
      memo: '두 번이나 말도 없이 안 나옴.',
    ),
    const _BlockedUser(
      name: 'coffee_holic',
      date: '2026.04.15',
      gender: Gender.female,
      memo: '단톡방에 계속 광고 링크 도배.',
    ),
    const _BlockedUser(
      name: '주말보드러',
      date: '2026.04.03',
      gender: Gender.male,
    ),
    const _BlockedUser(
      name: 'mina__',
      date: '2026.03.28',
      gender: Gender.female,
      memo: '반말에 무시하는 말투. 불편했음.',
    ),
    const _BlockedUser(
      name: '러닝크루대장',
      date: '2026.03.19',
      gender: Gender.male,
    ),
    const _BlockedUser(
      name: 'park_dev',
      date: '2026.03.05',
      gender: Gender.male,
      memo: '회비 걷고 잠수 탔어요.',
    ),
    const _BlockedUser(
      name: '카페투어__',
      date: '2026.02.21',
      gender: Gender.female,
      memo: '자꾸 사적인 연락 시도해서 차단함.',
    ),
  ];

  Future<void> _unblock(_BlockedUser user) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _UnblockDialog(name: user.name),
    );
    if (ok == true && mounted) {
      setState(() => _users.remove(user));
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('${user.name} 님을 차단 해제했어요'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _report(_BlockedUser user) async {
    final reason = await ReportScreen.show(context, user.name);
    if (reason != null && mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('${user.name} 님 신고를 접수했어요'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
        title: const Text('차단 목록',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _users.isEmpty
          ? const Center(
              child: Text('차단한 사용자가 없어요',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textTertiary)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    '차단한 사용자가 참여해 있는 모임은 내 화면에 나타나지 않아요. 차단 메모는 나만 볼 수 있어요.',
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: AppColors.textTertiary),
                  ),
                ),
                for (final user in _users)
                  _BlockedCard(
                    user: user,
                    onUnblock: () => _unblock(user),
                    onReport: () => _report(user),
                  ),
              ],
            ),
    );
  }
}

class _BlockedCard extends StatelessWidget {
  const _BlockedCard({
    required this.user,
    required this.onUnblock,
    required this.onReport,
  });
  final _BlockedUser user;
  final VoidCallback onUnblock;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final initial = user.name.isNotEmpty ? user.name.characters.first : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderTertiary, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: user.avatarBg,
                  shape: BoxShape.circle,
                ),
                child: Text(initial,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: user.avatarFg)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text('${user.date} 차단',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionButton(label: '차단 해제', onTap: onUnblock),
                  const SizedBox(height: 6),
                  _ActionButton(
                      label: '신고하기', danger: true, onTap: onReport),
                ],
              ),
            ],
          ),
          if (user.memo.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sticky_note_2_outlined,
                      size: 13, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(user.memo,
                        style: const TextStyle(
                            fontSize: 11.5,
                            height: 1.45,
                            color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnblockDialog extends StatelessWidget {
  const _UnblockDialog({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgPrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.bgCoral,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_open_rounded,
                  color: AppColors.coral, size: 26),
            ),
            const SizedBox(height: 18),
            const Text(
              '차단을 해제할까요?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
                children: [
                  TextSpan(
                    text: name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const TextSpan(text: ' 님이 다시 같은 모임·채팅에\n함께 나타날 수 있어요.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('차단 해제'),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textTertiary,
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.textDanger : AppColors.textSecondary;
    final border =
        danger ? AppColors.textDanger.withValues(alpha: 0.4) : AppColors.borderTertiary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 76,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: color)),
      ),
    );
  }
}
