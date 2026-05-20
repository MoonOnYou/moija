import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/filter_storage.dart';
import '../../data/meeting_repository.dart';
import '../../models/meeting_filter.dart';
import '../../theme/app_colors.dart';
import '../filter/filter_screen.dart';
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
  static final DateTime _today = DateTime(2026, 5, 16);

  final MeetingRepository _repository = MeetingRepository();
  final FilterStorage _storage = FilterStorage();
  late DateTime _windowStart = weekStartOf(_today);
  late DateTime _selectedDay = _today;
  MeetingFilter _filter = const MeetingFilter.empty();

  @override
  void initState() {
    super.initState();
    _loadFilter();
  }

  Future<void> _loadFilter() async {
    final loaded = await _storage.load();
    if (mounted) setState(() => _filter = loaded);
  }

  void _goToDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _windowStart = windowFollowing(_windowStart, day);
    });
  }

  Future<void> _openFilter() async {
    final result = await Navigator.push<MeetingFilter>(
      context,
      MaterialPageRoute(builder: (_) => FilterScreen(initial: _filter)),
    );
    if (result != null && mounted) {
      setState(() => _filter = result);
      await _storage.save(result);
    }
  }

  String _monthLabel() {
    final days = twoWeekGridFrom(_windowStart);
    final first = days.first;
    final last = days.last;
    if (first.month == last.month) {
      return DateFormat('y년 M월', 'ko_KR').format(first);
    }
    return '${first.year}년 ${first.month}–${last.month}월';
  }

  @override
  Widget build(BuildContext context) {
    final dayMeetings =
        _repository.meetingsOn(_selectedDay).where(_filter.matches).toList();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeHeader(monthLabel: _monthLabel()),
            const SizedBox(height: 8),
            FilterBar(activeCount: _filter.activeCount, onTap: _openFilter),
            TwoWeekCalendar(
              windowStart: _windowStart,
              selectedDay: _selectedDay,
              today: _today,
              repository: _repository,
              filter: _filter,
              onDaySelected: _goToDay,
              onWindowChanged: (ws) => setState(() => _windowStart = ws),
            ),
            SelectedDaySummary(
              selectedDay: _selectedDay,
              meetingCount: dayMeetings.length,
              filterCount: _filter.activeCount,
            ),
            Expanded(
              child: DayMeetingsPager(
                selectedDay: _selectedDay,
                today: _today,
                repository: _repository,
                filter: _filter,
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
