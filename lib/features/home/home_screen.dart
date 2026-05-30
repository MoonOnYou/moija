import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/filter_storage.dart';
import '../../data/meeting_repository.dart';
import '../../data/wallet.dart';
import '../../models/meeting_filter.dart';
import '../../shell/app_navigation.dart';
import '../../theme/app_colors.dart';
import '../filter/filter_screen.dart';
import '../meeting/create_meeting_screen.dart';
import '../meeting/diamond_recharge_screen.dart';
import 'calendar_grid.dart';
import 'widgets/day_meetings_pager.dart';
import 'widgets/filter_bar.dart';
import 'widgets/home_header.dart';
import 'widgets/selected_day_summary.dart';
import 'widgets/two_week_calendar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.today, this.repository});

  /// 기준 "오늘". 미지정 시 실제 현재 날짜를 사용한다(테스트에서 주입).
  final DateTime? today;

  /// 외부에서 공유할 모임 저장소. 미지정 시 자체 인스턴스를 생성한다.
  /// (AppShell이 홈/채팅에 같은 인스턴스를 넘겨 두 화면이 같은 데이터를 본다.)
  final MeetingRepository? repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  late DateTime _today = _dateOnly(widget.today ?? DateTime.now());

  late final MeetingRepository _repository =
      widget.repository ?? MeetingRepository();
  final FilterStorage _storage = FilterStorage();
  late DateTime _windowStart = weekStartOf(_today);
  late DateTime _selectedDay = _today;
  MeetingFilter _filter = const MeetingFilter.empty();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFilter();
    pendingFocusDay.addListener(_consumePendingFocus);
    // 위젯이 살아있는 동안 누적된 요청이 있으면 마운트 직후 1회 처리.
    _consumePendingFocus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pendingFocusDay.removeListener(_consumePendingFocus);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _refreshTodayIfChanged();
  }

  /// 자정을 넘긴 뒤 앱이 복귀하면 _today를 새 날짜로 교체한다.
  /// 사용자가 보고 있던 날짜가 옛 today였다면(평상시), 선택 날짜·캘린더도 새 today로 따라간다.
  /// 다른 날짜를 보고 있었다면 그대로 유지.
  void _refreshTodayIfChanged() {
    if (widget.today != null) return; // 테스트가 today를 주입하면 자동 갱신 안 함
    final newToday = _dateOnly(DateTime.now());
    if (newToday == _today) return;
    setState(() {
      final followToday = _selectedDay == _today;
      _today = newToday;
      if (followToday) {
        _selectedDay = newToday;
        _windowStart = weekStartOf(newToday);
      }
    });
  }

  /// 외부(예: 모임 생성 흐름)에서 요청한 날짜로 캘린더를 이동시킨 뒤
  /// 신호를 비워둔다(중복 처리를 막기 위함).
  void _consumePendingFocus() {
    final day = pendingFocusDay.value;
    if (day == null) return;
    _goToDay(day);
    pendingFocusDay.value = null;
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

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() {});
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
            HomeHeader(
              monthLabel: _monthLabel(),
              diamonds: Wallet.myDiamonds,
              onDiamondTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DiamondRechargeScreen(
                      currentDiamonds: Wallet.myDiamonds),
                ),
              ),
            ),
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
                onRefresh: _refresh,
                onDayChanged: _goToDay,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.coral,
        foregroundColor: AppColors.bgPrimary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateMeetingScreen(),
            ),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
