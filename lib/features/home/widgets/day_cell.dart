import 'package:flutter/material.dart';
import '../../../models/meeting.dart';
import '../../../theme/app_colors.dart';

class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
    required this.date,
    required this.meetings,
    required this.isPast,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final List<Meeting> meetings;
  final bool isPast;
  final bool isToday;
  final bool isSelected;
  final VoidCallback? onTap;

  static const double _numberRow = 22;
  static const double _gapAfterNumber = 3;
  static const double _chipHeight = 18;
  static const double _chipGap = 2;

  Color _numberColor() {
    if (isSelected) return Colors.white;
    if (isToday) return AppColors.coral;
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
          color: AppColors.coral,
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
          border: Border.all(color: AppColors.coral, width: 1.5),
        ),
        child: number,
      );
    }

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: isSelected ? AppColors.bgCoral : null,
        border: isSelected ? Border.all(color: AppColors.coral) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: _numberRow, child: Center(child: numberWidget)),
          const SizedBox(height: _gapAfterNumber),
          Expanded(child: _buildChips()),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(opacity: isPast ? 0.45 : 1.0, child: content),
    );
  }

  Widget _buildChips() {
    if (meetings.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        var maxRows = ((h + _chipGap) / (_chipHeight + _chipGap)).floor();
        if (maxRows < 1) maxRows = 1;

        final n = meetings.length;
        final int visible = (n <= maxRows) ? n : (maxRows - 1).clamp(0, n);
        final remaining = n - visible;

        final children = <Widget>[];
        for (var i = 0; i < visible; i++) {
          if (i > 0) children.add(const SizedBox(height: _chipGap));
          children.add(_chip(meetings[i]));
        }
        if (remaining > 0) {
          if (children.isNotEmpty) children.add(const SizedBox(height: _chipGap));
          children.add(_moreLabel(remaining));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }

  Widget _chip(Meeting m) {
    final text = '${m.categoryLabel}·${m.region}·${m.title}';
    return Container(
      height: _chipHeight,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.bgPrimary : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _moreLabel(int remaining) {
    return SizedBox(
      height: _chipHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '+$remaining',
          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
