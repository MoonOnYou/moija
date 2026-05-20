import 'package:flutter/material.dart';
import '../../../data/meeting_repository.dart';
import '../../../theme/app_colors.dart';
import '../calendar_grid.dart';
import 'day_cell.dart';

class TwoWeekCalendar extends StatelessWidget {
  const TwoWeekCalendar({
    super.key,
    required this.windowStart,
    required this.selectedDay,
    required this.today,
    required this.repository,
    required this.onDaySelected,
    required this.onWindowDelta,
  });

  final DateTime windowStart;
  final DateTime selectedDay;
  final DateTime today;
  final MeetingRepository repository;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<int> onWindowDelta; // 일 단위, -14 또는 +14

  static const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];
  static const double _rowHeight = 104;

  bool _isPast(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final t = DateTime(today.year, today.month, today.day);
    return day.isBefore(t);
  }

  @override
  Widget build(BuildContext context) {
    final days = twoWeekGridFrom(windowStart);
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v > 0) {
          onWindowDelta(-14); // 오른쪽으로 스와이프 → 이전 2주
        } else if (v < 0) {
          onWindowDelta(14); // 왼쪽으로 스와이프 → 다음 2주
        }
      },
      child: Column(
        children: [
          _weekdayHeader(),
          _weekRow(days.sublist(0, 7)),
          _weekRow(days.sublist(7, 14)),
        ],
      ),
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
                    meetings: repository.meetingsOn(date),
                    isPast: _isPast(date),
                    isToday: isSameDay(date, today),
                    isSelected: isSameDay(date, selectedDay),
                    onTap: () => onDaySelected(date),
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
