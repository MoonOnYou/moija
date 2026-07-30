import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/meeting.dart';
import '../../models/member.dart';
import '../../theme/app_colors.dart';
import 'withdrawal_flow.dart';

/// 탈퇴 전 방장 위임 화면 — 내가 방장인 모임 n개를 한 화면에서 멤버에게 넘긴다.
///
/// 선택은 "완료"를 누르기 전까지 이 화면 안에만 머물고(되돌리기 가능),
/// 완료 시점에 [WithdrawalSession.onDelegate]로 한 번에 반영한 뒤
/// [WithdrawalSession.handovers]에 기록한다.
///
/// 멤버가 나뿐인 모임은 넘길 사람이 없어 위임 대상이 아니다. 목록에는 안내로만
/// 보여주고(탈퇴 시 함께 정리), 방장이 모임을 닫는 동작은 제공하지 않는다.
class HostDelegationScreen extends StatefulWidget {
  const HostDelegationScreen({super.key, required this.session});

  final WithdrawalSession session;

  @override
  State<HostDelegationScreen> createState() => _HostDelegationScreenState();
}

class _HostDelegationScreenState extends State<HostDelegationScreen> {
  /// 이 화면에서 고른 새 방장(모임 id → 멤버). 완료 전까지는 세션에 반영하지 않는다.
  late final Map<String, Member> _staged = {...widget.session.handovers};

  /// 위임해야 하는 모임(넘길 멤버가 있는 것만).
  List<Meeting> get _meetings => widget.session.delegatableMeetings;

  /// 멤버가 나뿐이라 넘길 수 없는 모임 — 안내만 한다.
  List<Meeting> get _soloMeetings => widget.session.soloHostedMeetings;

  List<Member> _candidates(Meeting m) =>
      widget.session.candidatesOf?.call(m) ?? const [];

  bool get _allResolved => _meetings.every((m) => _staged.containsKey(m.id));

  Future<void> _pickNewHost(Meeting meeting) async {
    final candidates = _candidates(meeting);
    if (candidates.isEmpty) return;
    final picked = await Navigator.of(context).push<Member>(
      MaterialPageRoute(
        builder: (_) => _NewHostPickerScreen(
          meeting: meeting,
          candidates: candidates,
          current: _staged[meeting.id],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _staged[meeting.id] = picked);
  }

  void _undo(Meeting meeting) {
    setState(() => _staged.remove(meeting.id));
  }

  /// 완료 — 확인 후 훅을 호출해 실제 데이터에 반영하고 세션에 기록한다.
  Future<void> _finish() async {
    final fresh = {
      for (final m in _meetings)
        if (_staged.containsKey(m.id) &&
            !widget.session.handovers.containsKey(m.id))
          m.id: _staged[m.id]!,
    };
    if (fresh.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgPrimary,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('이대로 확정할까요?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final m in _meetings)
              if (fresh.containsKey(m.id))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('· ${m.title} → ${fresh[m.id]!.nickname}님',
                      style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.textPrimary)),
                ),
            const SizedBox(height: 4),
            const Text('확정하면 되돌릴 수 없어요.',
                style: TextStyle(
                    fontSize: 12.5, color: AppColors.textTertiary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary),
            child: const Text('더 볼게요'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            child: const Text('확정'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    for (final m in _meetings) {
      final newHost = fresh[m.id];
      if (newHost == null) continue;
      widget.session.onDelegate?.call(m, newHost);
      widget.session.handovers[m.id] = newHost;
    }

    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      content: Text('모임 ${fresh.length}개의 방장을 위임했어요'),
      duration: const Duration(seconds: 2),
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final total = _meetings.length;
    final done = _meetings.where((m) => _staged.containsKey(m.id)).length;

    return WithdrawalScaffold(
      appBarTitle: '방장 위임',
      heading: '방장 자리를 넘겨주세요',
      subtitle: Text.rich(
        TextSpan(children: [
          const TextSpan(text: '방장으로 운영 중인 모임 '),
          TextSpan(
              text: '$total개',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const TextSpan(text: '가 있어요. 모두 넘겨야 탈퇴를 진행할 수 있어요.'),
        ]),
      ),
      actions: [
        WithdrawalButton.secondary(
          label: '나중에 할게요',
          onPressed: () => Navigator.of(context).pop(),
        ),
        WithdrawalButton.primary(
          key: const Key('handover-done'),
          label: _allResolved ? '완료' : '$done/$total 위임됨',
          onPressed: _allResolved ? _finish : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProgressBar(done: done, total: total),
          const SizedBox(height: 16),
          for (final m in _meetings) ...[
            _HostedMeetingCard(
              meeting: m,
              newHost: _staged[m.id],
              locked: widget.session.handovers.containsKey(m.id),
              candidateCount: _candidates(m).length,
              onDelegate: () => _pickNewHost(m),
              onUndo: () => _undo(m),
            ),
            const SizedBox(height: 11),
          ],
          if (_soloMeetings.isNotEmpty) ...[
            _SoloMeetingsNotice(meetings: _soloMeetings),
            const SizedBox(height: 11),
          ],
          const SizedBox(height: 4),
          const _HandoverNotice(),
        ],
      ),
    );
  }
}

/// n개 중 몇 개를 정리했는지 보여주는 진행 바.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 1.0 : done / total;
    final complete = done == total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              complete
                  ? Icons.check_circle_rounded
                  : Icons.workspace_premium_rounded,
              size: 16,
              color: complete ? AppColors.textSuccess : AppColors.coral,
            ),
            const SizedBox(width: 6),
            Text(
              complete ? '모두 위임했어요' : '$total개 중 $done개 위임했어요',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: complete ? AppColors.textSuccess : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: AppColors.bgSecondary,
            valueColor: AlwaysStoppedAnimation<Color>(
                complete ? AppColors.mint : AppColors.coral),
          ),
        ),
      ],
    );
  }
}

/// 방장 모임 한 건 — 모임 정보 + 위임 버튼 또는 위임 결과.
class _HostedMeetingCard extends StatelessWidget {
  const _HostedMeetingCard({
    required this.meeting,
    required this.newHost,
    required this.locked,
    required this.candidateCount,
    required this.onDelegate,
    required this.onUndo,
  });

  final Meeting meeting;

  /// 이 화면에서 고른 새 방장. null이면 아직 위임 전.
  final Member? newHost;

  /// 이미 확정된 건(되돌리기 불가).
  final bool locked;
  final int candidateCount;
  final VoidCallback onDelegate;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final resolved = newHost != null;
    final when =
        DateFormat('M월 d일 (E) a h:mm', 'ko_KR').format(meeting.startTime);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: resolved ? AppColors.mint : AppColors.borderTertiary,
          width: resolved ? 1 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(meeting.icon,
                    size: 18, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meeting.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text('$when · ${meeting.region}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text('멤버 ${meeting.currentMembers}/${meeting.maxMembers}명',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (resolved)
            _ResolvedRow(
              newHost: newHost!,
              locked: locked,
              onUndo: onUndo,
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: Key('delegate-${meeting.id}'),
                onPressed: onDelegate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: AppColors.bgPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                child: Text('방장 위임 ($candidateCount명 중 선택)'),
              ),
            ),
        ],
      ),
    );
  }
}

/// 위임한 모임에 표시하는 결과 줄 + 되돌리기.
class _ResolvedRow extends StatelessWidget {
  const _ResolvedRow({
    required this.newHost,
    required this.locked,
    required this.onUndo,
  });

  final Member newHost;
  final bool locked;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 9, 7, 9),
      decoration: BoxDecoration(
        color: AppColors.bgSuccess,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded,
              size: 15, color: AppColors.textSuccess),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '${newHost.nickname}님에게 방장을 위임했어요',
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSuccess),
            ),
          ),
          if (!locked)
            TextButton(
              onPressed: onUndo,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
              child: const Text('되돌리기'),
            ),
        ],
      ),
    );
  }
}

/// 멤버가 나뿐이라 넘길 사람이 없는 모임 안내. 탈퇴를 막지 않는다.
class _SoloMeetingsNotice extends StatelessWidget {
  const _SoloMeetingsNotice({required this.meetings});

  final List<Meeting> meetings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.bgWarning,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFECD9B0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 15, color: AppColors.textWarning),
              const SizedBox(width: 6),
              Text('멤버가 나뿐인 모임 ${meetings.length}개',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textWarning)),
            ],
          ),
          const SizedBox(height: 6),
          for (final m in meetings)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('· ${m.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.45,
                      color: AppColors.textPrimary)),
            ),
          const SizedBox(height: 4),
          const Text('넘길 멤버가 없어 위임하지 않아도 돼요. 탈퇴하면 함께 정리돼요.',
              style: TextStyle(
                  fontSize: 11.5, height: 1.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// 위임 시 무슨 일이 일어나는지 안내.
class _HandoverNotice extends StatelessWidget {
  const _HandoverNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('위임하면 이렇게 돼요',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          SizedBox(height: 6),
          Text(
            '· 새 방장이 신청자 승인·공지·모임 관리 권한을 갖게 돼요.\n'
            '· 나는 모임에서 빠지고, 새 방장과 멤버에게 알림이 가요.\n'
            '· 확정 후에는 되돌릴 수 없어요.',
            style: TextStyle(
                fontSize: 11.5, height: 1.6, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// 새 방장 고르기 — 나를 뺀 참가자 중 한 명을 선택한다.
class _NewHostPickerScreen extends StatefulWidget {
  const _NewHostPickerScreen({
    required this.meeting,
    required this.candidates,
    this.current,
  });

  final Meeting meeting;
  final List<Member> candidates;
  final Member? current;

  @override
  State<_NewHostPickerScreen> createState() => _NewHostPickerScreenState();
}

class _NewHostPickerScreenState extends State<_NewHostPickerScreen> {
  late Member? _selected = widget.current;

  /// 매너점수가 가장 높은 후보 — "추천" 배지를 단다(동점이면 앞선 사람).
  Member get _recommended => widget.candidates.reduce(
      (a, b) => b.mannerScore > a.mannerScore ? b : a);

  @override
  Widget build(BuildContext context) {
    final recommended = _recommended;
    return WithdrawalScaffold(
      appBarTitle: '새 방장 선택',
      heading: '누구에게 방장을 넘길까요?',
      subtitle: Text.rich(
        TextSpan(children: [
          TextSpan(
              text: '"${widget.meeting.title}"',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const TextSpan(text: '의 멤버 중 한 명을 골라주세요.'),
        ]),
      ),
      actions: [
        WithdrawalButton.secondary(
          label: '취소',
          onPressed: () => Navigator.of(context).pop(),
        ),
        WithdrawalButton.primary(
          key: const Key('confirm-new-host'),
          label: _selected == null ? '멤버를 선택해주세요' : '${_selected!.nickname}님에게 위임',
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context).pop(_selected),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final m in widget.candidates) ...[
            _CandidateTile(
              member: m,
              selected: identical(_selected, m) ||
                  (_selected != null && _selected!.nickname == m.nickname),
              recommended: identical(m, recommended) &&
                  widget.candidates.length > 1,
              onTap: () => setState(() => _selected = m),
            ),
            const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

/// 후보 멤버 한 명 — 프로필 요약 + 선택 표시.
class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.member,
    required this.selected,
    required this.recommended,
    required this.onTap,
  });

  final Member member;
  final bool selected;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isMale = member.gender == Gender.male;
    return GestureDetector(
      key: Key('candidate-${member.nickname}'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.bgCoral : AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.coral : AppColors.borderTertiary,
            width: selected ? 1.4 : 0.5,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: isMale ? AppColors.bgInfo : AppColors.bgPink,
              child: Text(
                member.nickname.characters.first,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isMale ? AppColors.textInfo : AppColors.textPink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(member.nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded,
                          size: 13, color: Color(0xFFE6A700)),
                      const SizedBox(width: 2),
                      Text(member.mannerScore.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w600)),
                      if (recommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.bgWarning,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('추천',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textWarning)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                      '${member.birthYear}년생 · ${member.gender.label} · 활동 ${member.totalActivities}회',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text('나와 ${member.timesMetWithMe}번 만남',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 21,
              color: selected ? AppColors.coral : AppColors.borderTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
