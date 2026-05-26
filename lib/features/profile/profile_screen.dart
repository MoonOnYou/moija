import 'package:flutter/material.dart';
import '../../data/wallet.dart';
import '../../models/member.dart';
import '../../theme/app_colors.dart';
import '../meeting/diamond_recharge_screen.dart';
import 'edit_text_screen.dart';

/// 프로필 메인 화면.
/// 헤더(편집) · 자기소개(편집) · 다이아 충전 카드 · 정책/계정 메뉴.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 내 프로필 mock. 추후 백엔드 사용자 정보로 교체.
  String _nickname = '나';
  String _intro = '함께 한잔 좋아하고, 처음 만나는 사람 환영해요 :)';
  static const int _birthYear = 1998;
  static const Gender _gender = Gender.female;
  static const double _mannerScore = 4.7;
  static const int _totalActivities = 12;

  Future<void> _editNickname() async {
    final result = await EditTextScreen.show(
      context,
      title: '닉네임 수정',
      initial: _nickname,
      hint: '닉네임을 입력해 주세요',
      maxLength: 12,
    );
    if (result != null && result.isNotEmpty && mounted) {
      setState(() => _nickname = result);
    }
  }

  Future<void> _editIntro() async {
    final result = await EditTextScreen.show(
      context,
      title: '자기소개 수정',
      initial: _intro,
      hint: '함께하는 모임에서 나를 소개해 주세요',
      maxLength: 200,
      multiline: true,
    );
    if (result != null && mounted) {
      setState(() => _intro = result);
    }
  }

  void _stub(String label) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(
      content: Text('$label은 준비 중이에요'),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _confirmLeaveAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text(
            '탈퇴하면 모든 모임 이력과 다이아가 사라져요. 정말 탈퇴할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.textDanger),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
    if (ok == true) _stub('회원 탈퇴');
  }

  Future<void> _openRecharge() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DiamondRechargeScreen(
        currentDiamonds: Wallet.myDiamonds,
      ),
    ));
    if (mounted) setState(() {});
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
        title: const Text('프로필',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _ProfileHeader(
            nickname: _nickname,
            birthYear: _birthYear,
            gender: _gender,
            mannerScore: _mannerScore,
            totalActivities: _totalActivities,
            onEditNickname: _editNickname,
          ),
          const SizedBox(height: 12),
          _IntroCard(intro: _intro, onEdit: _editIntro),
          const SizedBox(height: 12),
          _DiamondCard(
            diamonds: Wallet.myDiamonds,
            onRecharge: _openRecharge,
          ),
          const SizedBox(height: 20),
          const _SectionTitle('내 정보'),
          _MenuTile(
              icon: Icons.favorite_border_rounded,
              label: '내 관심사',
              onTap: () => _stub('내 관심사 설정')),
          _MenuTile(
              icon: Icons.block_rounded,
              label: '차단 목록',
              onTap: () => _stub('차단 목록')),
          _MenuTile(
              icon: Icons.notifications_none_rounded,
              label: '알림 설정',
              onTap: () => _stub('알림 설정')),
          const SizedBox(height: 20),
          const _SectionTitle('약관 · 정책'),
          _MenuTile(
              icon: Icons.description_rounded,
              label: '서비스 이용약관',
              onTap: () => _stub('이용약관')),
          _MenuTile(
              icon: Icons.shield_rounded,
              label: '개인정보 처리방침',
              onTap: () => _stub('개인정보 처리방침')),
          _MenuTile(
              icon: Icons.place_rounded,
              label: '위치기반서비스 이용약관',
              onTap: () => _stub('위치기반서비스 이용약관')),
          _MenuTile(
              icon: Icons.gavel_rounded,
              label: '커뮤니티 가이드 · 신고 정책',
              onTap: () => _stub('커뮤니티 가이드')),
          const SizedBox(height: 20),
          const _SectionTitle('고객지원'),
          _MenuTile(
              icon: Icons.support_agent_rounded,
              label: '고객센터 · 문의하기',
              onTap: () => _stub('고객센터')),
          const _MenuTile(
              icon: Icons.info_outline_rounded,
              label: '앱 버전',
              trailing: '1.0.0'),
          const SizedBox(height: 20),
          const _SectionTitle('계정'),
          _MenuTile(
              icon: Icons.logout_rounded,
              label: '로그아웃',
              onTap: () => _stub('로그아웃')),
          _MenuTile(
              icon: Icons.person_remove_rounded,
              label: '회원 탈퇴',
              danger: true,
              onTap: _confirmLeaveAccount),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.nickname,
    required this.birthYear,
    required this.gender,
    required this.mannerScore,
    required this.totalActivities,
    required this.onEditNickname,
  });

  final String nickname;
  final int birthYear;
  final Gender gender;
  final double mannerScore;
  final int totalActivities;
  final VoidCallback onEditNickname;

  @override
  Widget build(BuildContext context) {
    final isMale = gender == Gender.male;
    final avatarBg = isMale ? AppColors.bgInfo : AppColors.bgPink;
    final avatarFg = isMale ? AppColors.textInfo : AppColors.textPink;
    final initial = nickname.isNotEmpty ? nickname.characters.first : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderTertiary, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: avatarBg,
            child: Text(initial,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: avatarFg)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      key: const Key('edit-nickname'),
                      onPressed: onEditNickname,
                      icon: const Icon(Icons.edit_rounded,
                          size: 16, color: AppColors.textTertiary),
                      tooltip: '닉네임 수정',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('$birthYear년생 · ${gender.label}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: Color(0xFFE6A700)),
                    const SizedBox(width: 2),
                    Text(mannerScore.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text('· 활동 $totalActivities회',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.intro, required this.onEdit});
  final String intro;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderTertiary, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('자기소개',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(
                  intro.isEmpty ? '자기소개를 작성해 보세요' : intro,
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: intro.isEmpty
                          ? AppColors.textTertiary
                          : AppColors.textPrimary),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('edit-intro'),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded,
                size: 18, color: AppColors.textTertiary),
            tooltip: '자기소개 수정',
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}

class _DiamondCard extends StatelessWidget {
  const _DiamondCard({required this.diamonds, required this.onRecharge});
  final int diamonds;
  final VoidCallback onRecharge;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderTertiary, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.diamond_rounded,
              size: 22, color: AppColors.textInfo),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('내 다이아',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary)),
                const SizedBox(height: 2),
                Text('$diamonds개',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          FilledButton(
            key: const Key('recharge-button'),
            onPressed: onRecharge,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.textInfo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 9),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
            child: const Text('충전하기'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary)),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.textDanger : AppColors.textPrimary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderTertiary, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: color)),
              ),
              if (trailing != null) ...[
                Text(trailing!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary)),
                const SizedBox(width: 4),
              ],
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
