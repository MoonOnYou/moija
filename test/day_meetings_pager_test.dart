import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moija/data/meeting_repository.dart';
import 'package:moija/features/home/widgets/day_meetings_pager.dart';
import 'package:moija/features/meeting/meeting_detail_screen.dart';

class _Host extends StatefulWidget {
  const _Host({required this.onDayChanged});
  final ValueChanged<DateTime> onDayChanged;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  DateTime _sel = DateTime(2026, 5, 16);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TextButton(
              onPressed: () => setState(() => _sel = DateTime(2026, 5, 20)),
              child: const Text('go'),
            ),
            Expanded(
              child: DayMeetingsPager(
                selectedDay: _sel,
                today: DateTime(2026, 5, 16),
                repository: MeetingRepository(),
                onDayChanged: widget.onDayChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  Future<DateTime?> swipe(WidgetTester tester, Offset offset) async {
    DateTime? changed;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayMeetingsPager(
          selectedDay: DateTime(2026, 5, 16),
          today: DateTime(2026, 5, 16),
          repository: MeetingRepository(),
          onDayChanged: (d) => changed = d,
        ),
      ),
    ));
    await tester.fling(find.byType(PageView), offset, 1000);
    await tester.pumpAndSettle();
    return changed;
  }

  testWidgets('swiping left advances to the next day', (tester) async {
    expect(await swipe(tester, const Offset(-400, 0)), DateTime(2026, 5, 17));
  });

  testWidgets('cannot swipe before today', (tester) async {
    expect(await swipe(tester, const Offset(400, 0)), isNull);
  });

  testWidgets('external multi-day change does not fire intermediate days',
      (tester) async {
    final changes = <DateTime>[];
    await tester.pumpWidget(_Host(onDayChanged: changes.add));
    await tester.tap(find.text('go')); // selectedDay 5/16 → 5/20
    await tester.pumpAndSettle();
    final intermediates = changes.where((d) =>
        d == DateTime(2026, 5, 17) ||
        d == DateTime(2026, 5, 18) ||
        d == DateTime(2026, 5, 19));
    expect(intermediates, isEmpty);
  });

  testWidgets('pull-to-refresh invokes onRefresh', (tester) async {
    var called = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayMeetingsPager(
          selectedDay: DateTime(2026, 5, 16),
          today: DateTime(2026, 5, 16),
          repository: MeetingRepository(),
          onRefresh: () async {
            called = true;
          },
          onDayChanged: (_) {},
        ),
      ),
    ));

    await tester.fling(find.byType(ListView).first, const Offset(0, 350), 1200);
    await tester.pumpAndSettle();

    expect(called, isTrue);
  });

  testWidgets('tapping a meeting card opens the detail screen',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayMeetingsPager(
          selectedDay: DateTime(2026, 5, 16),
          today: DateTime(2026, 5, 16),
          repository: MeetingRepository(),
          onDayChanged: (_) {},
        ),
      ),
    ));

    await tester.tap(find.text('퇴근 후 볼링'));
    await tester.pumpAndSettle();

    expect(find.byType(MeetingDetailScreen), findsOneWidget);
  });
}
