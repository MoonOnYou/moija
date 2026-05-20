import 'package:flutter/material.dart';
import '../../../data/meeting_repository.dart';
import '../../../theme/app_colors.dart';
import '../calendar_grid.dart';
import 'day_cell.dart';

/// 2주 윈도우를 좌우 스와이프(슬라이드 애니메이션)로 페이징하는 달력.
/// page 0 = 오늘 주 → 과거 창으로는 넘길 수 없다. 과거 날짜는 선택 불가.
class TwoWeekCalendar extends StatefulWidget {
  const TwoWeekCalendar({
    super.key,
    required this.windowStart,
    required this.selectedDay,
    required this.today,
    required this.repository,
    required this.onDaySelected,
    required this.onWindowChanged,
  });

  final DateTime windowStart;
  final DateTime selectedDay;
  final DateTime today;
  final MeetingRepository repository;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onWindowChanged;

  @override
  State<TwoWeekCalendar> createState() => _TwoWeekCalendarState();
}

class _TwoWeekCalendarState extends State<TwoWeekCalendar> {
  static const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];
  static const double _rowHeight = 104;

  late final DateTime _baseWindow = weekStartOf(widget.today);

  late final PageController _controller =
      PageController(initialPage: _pageOf(widget.windowStart));

  int _pageOf(DateTime windowStart) {
    final ws = DateTime(windowStart.year, windowStart.month, windowStart.day);
    return ws.difference(_baseWindow).inDays ~/ 14;
  }

  DateTime _windowOf(int page) => _baseWindow.add(Duration(days: 14 * page));

  bool _isPast(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final t = DateTime(widget.today.year, widget.today.month, widget.today.day);
    return day.isBefore(t);
  }

  @override
  void didUpdateWidget(TwoWeekCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부(windowFollowing 등)에서 창이 바뀌면 즉시 이동.
    final target = _pageOf(widget.windowStart);
    if (_controller.hasClients && _controller.page?.round() != target) {
      _controller.jumpToPage(target);
    }
  }

  void _onPageChanged(int page) {
    final ws = _windowOf(page);
    if (!isSameDay(ws, widget.windowStart)) {
      widget.onWindowChanged(ws);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _weekdayHeader(),
        SizedBox(
          height: _rowHeight * 2,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, page) {
              final days = twoWeekGridFrom(_windowOf(page));
              return Column(
                children: [
                  _weekRow(days.sublist(0, 7)),
                  _weekRow(days.sublist(7, 14)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _weekRow(List<DateTime> week) {
    return SizedBox(
      height: _rowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            for (final date in week)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(1.5),
                  child: DayCell(
                    date: date,
                    meetings: widget.repository.meetingsOn(date),
                    isPast: _isPast(date),
                    isToday: isSameDay(date, widget.today),
                    isSelected: isSameDay(date, widget.selectedDay),
                    onTap: _isPast(date)
                        ? null
                        : () => widget.onDaySelected(date),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _weekdayHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Row(
        children: List.generate(7, (i) {
          Color color = AppColors.textTertiary;
          if (i == 0) color = AppColors.textDanger;
          if (i == 6) color = AppColors.textInfo;
          return Expanded(
            child: Center(
              child: Text(
                _weekdayLabels[i],
                style: TextStyle(fontSize: 11, color: color),
              ),
            ),
          );
        }),
      ),
    );
  }
}
