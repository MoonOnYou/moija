import 'package:flutter/material.dart';
import '../../../data/meeting_repository.dart';
import '../../../models/meeting_filter.dart';
import '../../../theme/app_colors.dart';
import '../calendar_grid.dart';
import 'day_cell.dart';

/// 2주 윈도우를 좌우 스와이프(슬라이드 애니메이션)로 페이징하는 달력.
/// page 0 = 오늘 주 → 과거 창으로는 넘길 수 없다. 과거 날짜는 선택 불가.
/// 미래는 오늘로부터 [maxAheadDays]일까지만 보이며, 그 이후는 선택 불가.
const int kCalendarMaxAheadDays = 50;
class TwoWeekCalendar extends StatefulWidget {
  const TwoWeekCalendar({
    super.key,
    required this.windowStart,
    required this.selectedDay,
    required this.today,
    required this.repository,
    this.filter = const MeetingFilter.empty(),
    required this.onDaySelected,
    required this.onWindowChanged,
  });

  final DateTime windowStart;
  final DateTime selectedDay;
  final DateTime today;
  final MeetingRepository repository;
  final MeetingFilter filter;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onWindowChanged;

  @override
  State<TwoWeekCalendar> createState() => _TwoWeekCalendarState();
}

class _TwoWeekCalendarState extends State<TwoWeekCalendar> {
  static const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];
  static const double _rowHeight = 104;

  late final DateTime _baseWindow = weekStartOf(widget.today);

  // 자정 롤오버로 widget.today가 바뀌면 과거/범위 판정도 즉시 따라가도록 getter로 둔다.
  DateTime get _today =>
      DateTime(widget.today.year, widget.today.month, widget.today.day);

  /// 선택 가능한 마지막 날짜 — 오늘로부터 [kCalendarMaxAheadDays]일.
  DateTime get _maxDate =>
      _today.add(const Duration(days: kCalendarMaxAheadDays));

  /// _maxDate를 포함하는 윈도우까지만 페이징할 수 있도록 페이지 개수를 제한한다.
  late final int _pageCount =
      (_maxDate.difference(_baseWindow).inDays ~/ 14) + 1;

  late final PageController _controller =
      PageController(initialPage: _pageOf(widget.windowStart));

  int _pageOf(DateTime windowStart) {
    final ws = DateTime(windowStart.year, windowStart.month, windowStart.day);
    final page = ws.difference(_baseWindow).inDays ~/ 14;
    return page.clamp(0, _pageCount - 1);
  }

  DateTime _windowOf(int page) => _baseWindow.add(Duration(days: 14 * page));

  bool _isPast(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.isBefore(_today);
  }

  /// 오늘로부터 [kCalendarMaxAheadDays]일을 넘어선 날짜.
  bool _isBeyond(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.isAfter(_maxDate);
  }

  /// 과거이거나 표시 범위를 넘어서 선택할 수 없는 날짜.
  bool _isDisabled(DateTime d) => _isPast(d) || _isBeyond(d);

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
            itemCount: _pageCount,
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
                    meetings: widget.repository
                        .meetingsOn(date)
                        .where(widget.filter.matches)
                        .toList(),
                    isPast: _isDisabled(date),
                    isToday: isSameDay(date, widget.today),
                    isSelected: isSameDay(date, widget.selectedDay),
                    onTap: _isDisabled(date)
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
