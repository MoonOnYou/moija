import 'package:flutter/material.dart';
import '../../../data/meeting_repository.dart';
import '../../../theme/app_colors.dart';
import '../calendar_grid.dart';
import 'day_cell.dart';

class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.focusedMonth,
    required this.selectedDay,
    required this.today,
    required this.repository,
    required this.onDaySelected,
    required this.onMonthDelta,
  });

  final DateTime focusedMonth;
  final DateTime selectedDay;
  final DateTime today;
  final MeetingRepository repository;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<int> onMonthDelta; // -1 이전달, +1 다음달

  static const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    final days = buildMonthGrid(focusedMonth);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v > 0) {
          onMonthDelta(-1); // 오른쪽으로 스와이프 → 이전 달
        } else if (v < 0) {
          onMonthDelta(1); // 왼쪽으로 스와이프 → 다음 달
        }
      },
      child: Column(
        children: [
          _weekdayHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 3,
                mainAxisSpacing: 3,
                childAspectRatio: 0.62,
              ),
              itemBuilder: (context, i) {
                final date = days[i];
                return DayCell(
                  date: date,
                  meetings: repository.meetingsOn(date),
                  inFocusedMonth: date.month == focusedMonth.month,
                  isToday: isSameDay(date, today),
                  isSelected: isSameDay(date, selectedDay),
                  onTap: () => onDaySelected(date),
                );
              },
            ),
          ),
        ],
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
