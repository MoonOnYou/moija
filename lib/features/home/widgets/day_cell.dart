import 'package:flutter/material.dart';
import '../../../models/meeting.dart';
import '../../../theme/app_colors.dart';

class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
    required this.date,
    required this.meetings,
    required this.inFocusedMonth,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final List<Meeting> meetings;
  final bool inFocusedMonth;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  Color _numberColor() {
    if (isSelected) return Colors.white;
    if (isToday) return AppColors.textInfo;
    switch (date.weekday) {
      case DateTime.sunday:
        return AppColors.textDanger;
      case DateTime.saturday:
        return AppColors.textInfo;
      default:
        return AppColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final number = Text(
      '${date.day}',
      style: TextStyle(
        fontSize: 12,
        color: _numberColor(),
        fontWeight: (isToday || isSelected) ? FontWeight.w500 : FontWeight.w400,
      ),
    );

    Widget numberWidget = number;
    if (isSelected) {
      numberWidget = Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.textInfo,
          shape: BoxShape.circle,
        ),
        child: number,
      );
    } else if (isToday) {
      numberWidget = Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.textInfo, width: 1.5),
        ),
        child: number,
      );
    }

    final cell = Opacity(
      opacity: inFocusedMonth ? 1.0 : 0.45,
      child: Container(
        constraints: const BoxConstraints(minHeight: 66),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isSelected ? AppColors.bgInfo : null,
          border: isSelected
              ? Border.all(color: AppColors.borderInfo)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 22, child: Center(child: numberWidget)),
            const SizedBox(height: 3),
            if (meetings.isNotEmpty) _chip(meetings.first),
            if (meetings.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '+${meetings.length - 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: cell,
    );
  }

  Widget _chip(Meeting m) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.bgPrimary : m.category.chipBackground,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        m.category.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          height: 1.3,
          color: m.category.chipForeground,
        ),
      ),
    );
  }
}
