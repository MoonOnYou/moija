import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/meeting_repository.dart';
import '../../theme/app_colors.dart';
import 'widgets/filter_bar.dart';
import 'widgets/home_header.dart';
import 'widgets/meeting_card.dart';
import 'widgets/month_calendar.dart';
import 'widgets/selected_day_summary.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 목 데이터의 고정 "오늘".
  static final DateTime _today = DateTime(2026, 5, 16);

  final MeetingRepository _repository = MeetingRepository();
  late DateTime _focusedMonth = DateTime(_today.year, _today.month);
  late DateTime _selectedDay = _today;

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      // 인접 달의 (흐린) 셀을 탭하면 그 달로 포커스를 이동시켜
      // 선택일이 항상 보이는 그리드 안에 있도록 한다.
      _focusedMonth = DateTime(day.year, day.month);
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel =
        DateFormat('y년 M월', 'ko_KR').format(_focusedMonth);
    final dayMeetings = _repository.meetingsOn(_selectedDay);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeHeader(monthLabel: monthLabel),
            const SizedBox(height: 8),
            const FilterBar(),
            MonthCalendar(
              focusedMonth: _focusedMonth,
              selectedDay: _selectedDay,
              today: _today,
              repository: _repository,
              onDaySelected: _selectDay,
              onMonthDelta: _changeMonth,
            ),
            SelectedDaySummary(
              selectedDay: _selectedDay,
              meetingCount: dayMeetings.length,
            ),
            Expanded(
              child: dayMeetings.isEmpty
                  ? const _EmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      children: [
                        for (final m in dayMeetings) MeetingCard(meeting: m),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.textPrimary,
        foregroundColor: AppColors.bgPrimary,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
