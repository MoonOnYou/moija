import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/features/filter/filter_screen.dart';
import 'package:moija/models/meeting_category.dart';
import 'package:moija/models/meeting_filter.dart';
import 'package:moija/models/time_band.dart';

class _Holder {
  MeetingFilter? value;
}

Widget _host(_Holder holder) => MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                holder.value = await Navigator.push<MeetingFilter>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const FilterScreen(initial: MeetingFilter.empty()),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('selecting category + time band and saving returns them',
      (tester) async {
    final holder = _Holder();
    await tester.pumpWidget(_host(holder));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('방탈출'));
    await tester.pump();
    await tester.tap(find.text('저녁'));
    await tester.pump();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(holder.value!.categories, contains(MeetingCategory.escapeRoom));
    expect(holder.value!.timeBands, contains(TimeBand.evening));
  });

  testWidgets('reset clears selections before saving', (tester) async {
    final holder = _Holder();
    await tester.pumpWidget(_host(holder));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('방탈출'));
    await tester.pump();
    await tester.tap(find.text('초기화'));
    await tester.pump();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(holder.value!.isEmpty, isTrue);
  });
}
