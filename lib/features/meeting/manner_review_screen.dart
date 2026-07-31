import 'dart:async';

import 'package:flutter/material.dart';
import '../../data/meeting_repository.dart';
import '../../models/meeting.dart';
import '../../models/member.dart';
import '../../theme/app_colors.dart';
import '../common/block_screen.dart';

/// 종료된 모임의 팀원 매너를 평가하는 화면.
/// 멤버 카드마다 별점 1~5 선택 → 제출, 또는 차단/건너뛰기 중 하나로 처리한다.
class MannerReviewScreen extends StatefulWidget {
  const MannerReviewScreen({
    super.key,
    required this.repository,
    required this.meeting,
  });

  final MeetingRepository repository;
  final Meeting meeting;

  @override
  State<MannerReviewScreen> createState() => _MannerReviewScreenState();
}

class _MannerReviewScreenState extends State<MannerReviewScreen> {
  final GlobalKey<AnimatedListState> _listKey =
      GlobalKey<AnimatedListState>();
  late final List<Member> _pending;

  static const _dismissDuration = Duration(milliseconds: 380);

  /// 마지막 카드를 처리한 뒤 완료 화면을 보여주는 시간. 이후 자동으로 닫힌다.
  static const _autoCloseDelay = Duration(milliseconds: 900);

  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    final all = widget.repository.participantsOf(widget.meeting);
    // 호스트(=나) 제외.
    _pending = all.length > 1 ? all.sublist(1).toList() : <Member>[];
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _toast(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ));
  }

  void _dismiss(Member m, {String? toast}) {
    final i = _pending.indexOf(m);
    if (i < 0) return;
    final removed = _pending[i];
    _pending.removeAt(i);
    _listKey.currentState?.removeItem(
      i,
      (ctx, anim) => _animatedItem(removed, anim),
      duration: _dismissDuration,
    );
    if (toast != null) _toast(toast);

    if (_pending.isEmpty) {
      // 마지막 카드가 빠져나간 뒤 완료 화면을 잠깐 보여주고 화면을 닫는다.
      Future.delayed(_dismissDuration, () {
        if (!mounted) return;
        setState(() {});
        _autoCloseTimer = Timer(_autoCloseDelay, _closeIfCurrent);
      });
    } else {
      setState(() {});
    }
  }

  /// 이 화면이 최상단일 때만 닫는다(차단 화면 등이 위에 떠 있으면 건너뛴다).
  /// [Navigator.maybePop]이라 첫 라우트면 아무 일도 일어나지 않는다.
  void _closeIfCurrent() {
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    Navigator.of(context).maybePop();
  }

  Widget _animatedItem(Member m, Animation<double> animation) {
    // 슬라이드·페이드는 앞쪽 70% 구간에서 또렷이, size 축소는 뒤쪽 60% 구간에서.
    final slideAndFade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    );
    final sizeShrink = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );
    return SizeTransition(
      sizeFactor: sizeShrink,
      axisAlignment: 0,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1.5, 0),
          end: Offset.zero,
        ).animate(slideAndFade),
        child: FadeTransition(
          opacity: slideAndFade,
          // ValueKey로 State 식별 — 없으면 카드 dismiss 후 다음 카드가 옛 State(별점)를 재사용한다.
          child: _MannerCard(
            key: ValueKey('manner-card-${m.nickname}'),
            member: m,
            onSubmit: (stars) =>
                _dismiss(m, toast: '${m.nickname}님에게 ★$stars점을 줬어요'),
            onBlock: () async {
              final memo = await BlockScreen.show(context, m.nickname);
              if (memo != null && mounted) {
                _dismiss(m, toast: '${m.nickname}님을 차단했어요');
              }
            },
            onSkip: () => _dismiss(m),
          ),
        ),
      ),
    );
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
        title: Text(
          _pending.isEmpty ? '매너 평가' : '매너 평가 ${_pending.length}명',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: _pending.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 48, color: AppColors.textTertiary),
                  SizedBox(height: 12),
                  Text('모두 평가했어요',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  SizedBox(height: 4),
                  Text('함께해 주셔서 고마워요!',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textTertiary)),
                ],
              ),
            )
          : AnimatedList(
              key: _listKey,
              initialItemCount: _pending.length,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemBuilder: (ctx, i, animation) {
                final m = _pending[i];
                return _animatedItem(m, animation);
              },
            ),
    );
  }
}

class _MannerCard extends StatefulWidget {
  const _MannerCard({
    super.key,
    required this.member,
    required this.onSubmit,
    required this.onBlock,
    required this.onSkip,
  });

  final Member member;
  final ValueChanged<int> onSubmit;
  final VoidCallback onBlock;
  final VoidCallback onSkip;

  @override
  State<_MannerCard> createState() => _MannerCardState();
}

class _MannerCardState extends State<_MannerCard> {
  int _stars = 0;

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final isMale = m.gender == Gender.male;
    final avatarBg = isMale ? AppColors.bgInfo : AppColors.bgPink;
    final avatarFg = isMale ? AppColors.textInfo : AppColors.textPink;
    final canSubmit = _stars > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderTertiary, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: avatarBg,
                child: Text(m.nickname.characters.first,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: avatarFg)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.nickname,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${m.birthYear}년생 · ${m.gender.label}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('${m.nickname}님과 함께한 시간 어떠셨어요?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.35)),
          const SizedBox(height: 10),
          _StarPicker(
            value: _stars,
            onPick: (s) => setState(() => _stars = s),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              canSubmit ? '$_stars점' : '별을 눌러 점수를 선택하세요',
              style: TextStyle(
                fontSize: 11,
                color: canSubmit
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
                fontWeight:
                    canSubmit ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBlock,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDanger,
                    side: const BorderSide(color: AppColors.borderTertiary),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('차단'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: widget.onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('건너뛰기'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: canSubmit ? () => widget.onSubmit(_stars) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: AppColors.bgPrimary,
                    disabledBackgroundColor: AppColors.bgTertiary,
                    disabledForegroundColor: AppColors.textTertiary,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('제출'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 별 5개. 선택된 만큼 진한 노란색, 나머지는 옅은 회색.
class _StarPicker extends StatelessWidget {
  const _StarPicker({required this.value, required this.onPick});

  final int value;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            key: ValueKey('star-$i'),
            tooltip: '$i점',
            onPressed: () => onPick(i),
            icon: Icon(
              Icons.star_rounded,
              size: 34,
              color: i <= value
                  ? const Color(0xFFE6A700)
                  : AppColors.borderTertiary,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            constraints: const BoxConstraints(),
            splashRadius: 22,
          ),
      ],
    );
  }
}
