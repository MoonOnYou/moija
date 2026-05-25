import 'package:flutter/material.dart';
import '../../data/meeting_repository.dart';
import '../../models/applicant.dart';
import '../../models/meeting.dart';
import '../../models/member.dart';
import '../../theme/app_colors.dart';
import '../chat/chat_preview.dart' show pendingApplicantsFor;

/// 방장이 승인제 모임의 신청자를 검토하는 화면.
/// 신청자 카드(프로필 전체 + 방장에게 한마디) + 카드 하단 거절/수락 버튼.
class ApplicantReviewScreen extends StatefulWidget {
  const ApplicantReviewScreen({
    super.key,
    required this.repository,
    required this.meeting,
  });

  final MeetingRepository repository;
  final Meeting meeting;

  @override
  State<ApplicantReviewScreen> createState() =>
      _ApplicantReviewScreenState();
}

class _ApplicantReviewScreenState extends State<ApplicantReviewScreen> {
  final GlobalKey<AnimatedListState> _listKey =
      GlobalKey<AnimatedListState>();
  late final List<Applicant> _pending;

  static const _dismissDuration = Duration(milliseconds: 380);

  @override
  void initState() {
    super.initState();
    _pending =
        _seedApplicants(widget.meeting, widget.repository.memberPool);
  }

  void _handle(Applicant a, {required bool accepted}) {
    final i = _pending.indexOf(a);
    if (i < 0) return;
    final removed = _pending[i];
    _pending.removeAt(i);
    _listKey.currentState?.removeItem(
      i,
      (ctx, anim) => _animatedItem(removed, anim),
      duration: _dismissDuration,
    );

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(
      content: Text(accepted
          ? '${a.member.nickname}님 신청을 수락했어요'
          : '${a.member.nickname}님 신청을 거절했어요'),
      duration: const Duration(seconds: 2),
    ));

    if (_pending.isEmpty) {
      // 마지막 카드의 슬라이드 애니메이션이 끝난 뒤 빈 상태로 전환.
      Future.delayed(_dismissDuration, () {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {}); // AppBar 카운트 갱신
    }
  }

  Widget _animatedItem(Applicant a, Animation<double> animation) {
    // 슬라이드·페이드는 dismiss 앞쪽 70% 구간에서 또렷이 진행,
    // size 축소는 뒤쪽 50% 구간에서 일어나 다른 카드가 부드럽게 위로 올라온다.
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
          child: _ApplicantCard(
            applicant: a,
            onAccept: () => _handle(a, accepted: true),
            onReject: () => _handle(a, accepted: false),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          _pending.isEmpty ? '신청자 검토' : '신청자 ${_pending.length}명',
          style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: _pending.isEmpty
          ? const Center(
              child: Text('처리할 신청자가 없어요',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textTertiary)),
            )
          : AnimatedList(
              key: _listKey,
              initialItemCount: _pending.length,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemBuilder: (ctx, i, animation) {
                final a = _pending[i];
                return _animatedItem(a, animation);
              },
            ),
    );
  }
}

/// 모임 id 시드로 결정적 신청자 mock을 만든다.
/// 첫 멤버는 호스트로 가정해 건너뛰고, 나머지 풀에서 순환 선택.
List<Applicant> _seedApplicants(Meeting m, List<Member> pool) {
  if (pool.length < 2) return const [];
  final h = m.id.hashCode.abs();
  final n = pendingApplicantsFor(m);
  const messages = <String?>[
    '모임 처음이에요. 잘 부탁드려요!',
    '꼭 가보고 싶었어요. 분위기 망치지 않을게요',
    null,
    '시간 맞춰 갈게요 :)',
    '같은 동네라 반가워요',
    null,
    '저도 자주 가는 곳이에요. 같이 가고 싶어요',
  ];
  // 호스트(첫 멤버) 제외.
  final candidates = pool.sublist(1);
  return [
    for (var i = 0; i < n; i++)
      Applicant(
        member: candidates[(h + i) % candidates.length],
        message: messages[(h + i) % messages.length],
      ),
  ];
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({
    required this.applicant,
    required this.onAccept,
    required this.onReject,
  });

  final Applicant applicant;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final m = applicant.member;
    final isMale = m.gender == Gender.male;
    final avatarBg = isMale ? AppColors.bgInfo : AppColors.bgPink;
    final avatarFg = isMale ? AppColors.textInfo : AppColors.textPink;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderTertiary, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: avatarBg,
                child: Text(
                  m.nickname.characters.first,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: avatarFg),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // 닉네임 옆에 별점을 바로 붙여 보여준다.
                        Flexible(
                          child: Text(m.nickname,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star,
                            size: 14, color: Color(0xFFE6A700)),
                        const SizedBox(width: 2),
                        Text(m.mannerScore.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${m.birthYear}년생 · ${m.gender.label}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                        '활동 ${m.totalActivities}회 · 나와 ${m.timesMetWithMe}번 만남',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(m.intro,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
          if (applicant.message != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 13, color: AppColors.textSecondary),
                      SizedBox(width: 6),
                      Text('방장에게 한마디',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(applicant.message!,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.4)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDanger,
                    side: const BorderSide(color: AppColors.borderTertiary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('거절'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.bgPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('수락'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
