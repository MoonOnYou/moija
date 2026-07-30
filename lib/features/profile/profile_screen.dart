import 'package:flutter/material.dart';
import '../../data/api/auth_api.dart' show logout;
import '../../data/api/me_api.dart';
import '../../data/auth/auth_store.dart';
import '../../data/meeting_repository.dart';
import '../../data/wallet.dart';
import '../../models/auth_user.dart';
import '../../models/meeting.dart';
import '../../models/member.dart';
import '../../shell/app_navigation.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../meeting/diamond_recharge_screen.dart';
import '../withdrawal/withdrawal_flow.dart';
import 'block_list_screen.dart';
import 'edit_text_screen.dart';

/// 프로필 메인 화면.
/// 헤더(편집) · 자기소개(편집) · 다이아 충전 카드 · 정책/계정 메뉴.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.repository});

  /// 탈퇴 시 방장 모임을 확인·위임하는 데 쓴다. 주입이 없으면(테스트/오프라인)
  /// 방장 모임이 없는 것으로 보고 위임 단계를 건너뛴다.
  final MeetingRepository? repository;

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

  @override
  void initState() {
    super.initState();
    _refreshMe();
  }

  /// 로그인 상태면 서버에서 최신 프로필(매너점수·활동수 등)을 받아 갱신한다.
  Future<void> _refreshMe() async {
    if (AuthStore.instance.user == null) return;
    try {
      final me = await fetchMe();
      await AuthStore.instance.updateUser(me);
    } catch (_) {
      // 실패 시 저장된 프로필을 유지한다.
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );

  Future<void> _editNickname() async {
    final user = AuthStore.instance.user;
    final result = await EditTextScreen.show(
      context,
      title: '닉네임 수정',
      initial: user?.nickname ?? _nickname,
      hint: '닉네임을 입력해 주세요',
      maxLength: 12,
    );
    if (result == null || result.isEmpty || !mounted) return;
    if (user != null) {
      try {
        final updated = await updateProfile(nickname: result);
        await AuthStore.instance.updateUser(updated);
      } catch (_) {
        if (mounted) _toast('닉네임 수정에 실패했어요');
      }
    } else {
      setState(() => _nickname = result);
    }
  }

  Future<void> _editIntro() async {
    final user = AuthStore.instance.user;
    final result = await EditTextScreen.show(
      context,
      title: '자기소개 수정',
      initial: user?.intro ?? _intro,
      hint: '함께하는 모임에서 나를 소개해 주세요',
      maxLength: 200,
      multiline: true,
    );
    if (result == null || !mounted) return;
    if (user != null) {
      try {
        final updated = await updateProfile(intro: result);
        await AuthStore.instance.updateUser(updated);
      } catch (_) {
        if (mounted) _toast('자기소개 수정에 실패했어요');
      }
    } else {
      setState(() => _intro = result);
    }
  }

  Future<void> _openLogin() async {
    await LoginScreen.show(context);
    // 로그인 성공 시 userNotifier가 갱신되어 화면이 자동으로 다시 그려진다.
  }

  Future<void> _logout() async {
    final refresh = AuthStore.instance.refreshToken;
    if (refresh != null) await logout(refresh);
    await AuthStore.instance.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('로그아웃되었어요'),
        duration: Duration(seconds: 2),
      ));
    }
  }

  void _stub(String label) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(
      content: Text('$label은 준비 중이에요'),
      duration: const Duration(seconds: 2),
    ));
  }

  /// 내가 방장인 모임들(탈퇴 전 위임 대상).
  List<Meeting> get _hostedMeetings {
    final repo = widget.repository;
    if (repo == null) return const [];
    return [
      for (final m in repo.allMeetings)
        if (repo.myHostedIds.contains(m.id)) m,
    ]..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// 위임 후보 — 모임 참가자 중 방장(첫 번째 = 나)을 뺀 멤버들.
  List<Member> _handoverCandidates(Meeting m) {
    final repo = widget.repository;
    if (repo == null) return const [];
    final participants = repo.participantsOf(m);
    return participants.length <= 1 ? const [] : participants.sublist(1);
  }

  void _leaveAccount() {
    final repo = widget.repository;
    final hosted = _hostedMeetings;
    WithdrawalFlow.start(
      context,
      session: WithdrawalSession(
        // 로그인 사용자의 번호(없으면 mock).
        phone: AuthStore.instance.user?.phone ?? '01012345678',
        diamonds: Wallet.myDiamonds,
        mannerScore: _mannerScore,
        activities: _totalActivities,
        blockCount: 3,
        joinedCount: 3,
        hostedMeetings: hosted,
        candidatesOf: _handoverCandidates,
        // 위임은 확정 즉시 저장소에 반영한다(내모임·채팅 탭에 바로 보인다).
        onDelegate: (meeting, _) {
          repo?.delegateHost(meeting.id);
          myMeetingsRevision.value++;
        },
      ),
    );
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
    return ValueListenableBuilder<AuthUser?>(
      valueListenable: AuthStore.instance.userNotifier,
      builder: (context, user, _) {
        // 로그인 사용자가 있으면 서버 프로필을, 없으면 mock을 표시한다.
        final nickname = user?.nickname ?? _nickname;
        final intro = user?.intro ?? _intro;
        final birthYear = user?.birthYear ?? _birthYear;
        final gender = user?.gender ?? _gender;
        final mannerScore = user?.mannerScore ?? _mannerScore;
        final totalActivities = user?.totalActivities ?? _totalActivities;
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
            nickname: nickname,
            birthYear: birthYear,
            gender: gender,
            mannerScore: mannerScore,
            totalActivities: totalActivities,
            onEditNickname: _editNickname,
          ),
          const SizedBox(height: 12),
          _IntroCard(intro: intro, onEdit: _editIntro),
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
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const BlockListScreen()))),
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
          if (user == null)
            _MenuTile(
                key: const Key('signup-entry'),
                icon: Icons.login_rounded,
                label: '로그인 · 회원가입',
                onTap: _openLogin)
          else
            _MenuTile(
                icon: Icons.logout_rounded,
                label: '로그아웃',
                onTap: _logout),
          _MenuTile(
              icon: Icons.person_remove_rounded,
              label: '회원 탈퇴',
              danger: true,
              onTap: _leaveAccount),
          const SizedBox(height: 24),
        ],
      ),
        );
      },
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
    super.key,
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
