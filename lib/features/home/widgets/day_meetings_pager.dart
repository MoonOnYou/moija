import 'package:flutter/material.dart';
import '../../../data/meeting_repository.dart';
import '../../../theme/app_colors.dart';
import '../calendar_grid.dart';
import 'meeting_card.dart';

/// 모임 리스트를 가로 스와이프로 날짜 단위 전환하는 페이저.
/// 왼쪽 스와이프=다음 날, 오른쪽=이전 날.
class DayMeetingsPager extends StatefulWidget {
  const DayMeetingsPager({
    super.key,
    required this.selectedDay,
    required this.repository,
    required this.onDayChanged,
  });

  final DateTime selectedDay;
  final MeetingRepository repository;
  final ValueChanged<DateTime> onDayChanged;

  @override
  State<DayMeetingsPager> createState() => _DayMeetingsPagerState();
}

class _DayMeetingsPagerState extends State<DayMeetingsPager> {
  // 페이지 인덱스 ↔ 날짜 매핑 기준.
  static final DateTime _epoch = DateTime(2026, 5, 16);
  static const int _basePage = 100000;

  late final PageController _controller =
      PageController(initialPage: _pageOf(widget.selectedDay));

  static int _pageOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return _basePage + day.difference(_epoch).inDays;
  }

  static DateTime _dateOf(int page) =>
      _epoch.add(Duration(days: page - _basePage));

  @override
  void didUpdateWidget(DayMeetingsPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부(달력 탭)에서 선택일이 바뀌면 해당 페이지로 애니메이션 이동.
    final target = _pageOf(widget.selectedDay);
    if (_controller.hasClients && _controller.page?.round() != target) {
      _controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
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
      itemBuilder: (context, page) {
        final meetings = widget.repository.meetingsOn(_dateOf(page));
        if (meetings.isEmpty) return const _EmptyDay();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [for (final m in meetings) MeetingCard(meeting: m)],
        );
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
