import 'package:flutter/material.dart';
import '../../../data/meeting_repository.dart';
import '../../../models/meeting_filter.dart';
import '../../../theme/app_colors.dart';
import '../../meeting/meeting_detail_screen.dart';
import '../calendar_grid.dart';
import 'meeting_card.dart';
import 'two_week_calendar.dart' show kCalendarMaxAheadDays;

/// 모임 리스트를 가로 스와이프로 날짜 단위 전환하는 페이저.
/// 왼쪽 스와이프=다음 날(오늘로부터 [kCalendarMaxAheadDays]일에서 멈춤),
/// 오른쪽=이전 날(오늘에서 멈춤).
/// [onRefresh]가 주어지면 각 페이지를 당겨서 새로고침할 수 있다.
class DayMeetingsPager extends StatefulWidget {
  const DayMeetingsPager({
    super.key,
    required this.selectedDay,
    required this.today,
    required this.repository,
    this.filter = const MeetingFilter.empty(),
    this.onRefresh,
    required this.onDayChanged,
  });

  final DateTime selectedDay;
  final DateTime today;
  final MeetingRepository repository;
  final MeetingFilter filter;
  final Future<void> Function()? onRefresh;
  final ValueChanged<DateTime> onDayChanged;

  @override
  State<DayMeetingsPager> createState() => _DayMeetingsPagerState();
}

class _DayMeetingsPagerState extends State<DayMeetingsPager> {
  // page 0 = 오늘. 음수 페이지가 없어 오늘 이전으로 스와이프 불가.
  // 자정 롤오버로 widget.today가 바뀌면 바닥도 함께 이동하도록 getter로 둔다
  // (late final로 고정하면 옛 오늘이 바닥에 남아 이전 날로 넘어가는 버그가 생긴다).
  DateTime get _epoch =>
      DateTime(widget.today.year, widget.today.month, widget.today.day);

  // 오늘(0) ~ 오늘+50일(50) → 총 51페이지. 그 이후로는 넘길 수 없다.
  static const int _pageCount = kCalendarMaxAheadDays + 1;

  late final PageController _controller =
      PageController(initialPage: _pageOf(widget.selectedDay));

  int _pageOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.difference(_epoch).inDays.clamp(0, _pageCount - 1);
  }

  DateTime _dateOf(int page) => _epoch.add(Duration(days: page));

  @override
  void didUpdateWidget(DayMeetingsPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부(달력 탭)에서 선택일이 바뀌면 즉시 이동(중간 페이지 휩쓸기 방지).
    final target = _pageOf(widget.selectedDay);
    if (_controller.hasClients && _controller.page?.round() != target) {
      _controller.jumpToPage(target);
    }
  }

  void _onPageChanged(int page) {
    final day = _dateOf(page);
    if (!isSameDay(day, widget.selectedDay)) {
      widget.onDayChanged(day);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      onPageChanged: _onPageChanged,
      itemCount: _pageCount,
      itemBuilder: (context, page) {
        final meetings = widget.repository
            .meetingsOn(_dateOf(page))
            .where(widget.filter.matches)
            .toList();

        final Widget list = meetings.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [SizedBox(height: 120), _EmptyDay()],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  for (final m in meetings)
                    MeetingCard(
                      meeting: m,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MeetingDetailScreen(
                              meeting: m, repository: widget.repository),
                        ),
                      ),
                    ),
                ],
              );

        final onRefresh = widget.onRefresh;
        if (onRefresh == null) return list;
        return RefreshIndicator(onRefresh: onRefresh, child: list);
      },
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '이 날에는 모임이 없어요',
        style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
      ),
    );
  }
}
