import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/meeting_repository.dart';
import '../../theme/app_colors.dart';
import 'calendar_grid.dart';
import 'widgets/day_meetings_pager.dart';
import 'widgets/filter_bar.dart';
import 'widgets/home_header.dart';
import 'widgets/selected_day_summary.dart';
import 'widgets/two_week_calendar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 목 데이터의 고정 "오늘".
  static final DateTime _today = DateTime(2026, 5, 16);

  final MeetingRepository _repository = MeetingRepository();
  late DateTime _windowStart = weekStartOf(_today);
  late DateTime _selectedDay = _today;

  /// 달력 탭(미래/오늘 날짜)과 리스트 스와이프 공통 진입점.
  void _goToDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _windowStart = windowFollowing(_windowStart, day);
    });
  }

  String _monthLabel() {
    final days = twoWeekGridFrom(_windowStart);
    final first = days.first;
    final last = days.last;
    if (first.month == last.month) {
      return DateFormat('y년 M월', 'ko_KR').format(first);
    }
    // 두 달에 걸치면 "2026년 5–6월" 형태.
    return '${first.year}년 ${first.month}–${last.month}월';
  }

  @override
  Widget build(BuildContext context) {
    final dayMeetings = _repository.meetingsOn(_selectedDay);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeHeader(monthLabel: _monthLabel()),
            const SizedBox(height: 8),
            const FilterBar(),
            TwoWeekCalendar(
              windowStart: _windowStart,
              selectedDay: _selectedDay,
              today: _today,
              repository: _repository,
              onDaySelected: _goToDay,
              onWindowChanged: (ws) => setState(() => _windowStart = ws),
            ),
            SelectedDaySummary(
              selectedDay: _selectedDay,
              meetingCount: dayMeetings.length,
            ),
            Expanded(
              child: DayMeetingsPager(
                selectedDay: _selectedDay,
                today: _today,
                repository: _repository,
                onDayChanged: _goToDay,
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
