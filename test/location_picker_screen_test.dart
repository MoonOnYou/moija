import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/features/filter/location_picker_screen.dart';

void main() {
  testWidgets('drill into 서울, select 2호선, 완료 returns the node id',
      (tester) async {
    Set<String>? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await Navigator.push<Set<String>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LocationPickerScreen(initial: {}),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('서울'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2호선'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    expect(result, contains('seoul-line2'));
  });

  testWidgets('keeps initial selections and accumulates new ones',
      (tester) async {
    Set<String>? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await Navigator.push<Set<String>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LocationPickerScreen(initial: {'seoul-line1'}),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('서울'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2호선'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    expect(result, containsAll(<String>['seoul-line1', 'seoul-line2']));
  });

  testWidgets('system back from region detail returns to the region list',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push<Set<String>>(
                context,
                MaterialPageRoute(
                  builder: (_) => const LocationPickerScreen(initial: {}),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('대구'));
    await tester.pumpAndSettle();
    expect(find.text('대구1호선'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('대구1호선'), findsNothing);
    expect(find.text('장소 선택'), findsOneWidget);
  });

  testWidgets('selection survives system back and is returned on 완료',
      (tester) async {
    Set<String>? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await Navigator.push<Set<String>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LocationPickerScreen(initial: {}),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('대구'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('대구1호선')); // 체크
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute(); // 시스템 back → 시/도 목록
    await tester.pumpAndSettle();

    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    expect(result, contains('daegu-line1'));
  });

  testWidgets('singleSelect: 리프 탭 시 즉시 단일 id로 pop', (tester) async {
    Set<String>? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await Navigator.push<Set<String>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LocationPickerScreen(
                        initial: {}, singleSelect: true),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('서울'));
    await tester.pumpAndSettle();
    expect(find.text('완료'), findsNothing); // 단일 모드엔 완료 버튼 없음
    await tester.tap(find.text('2호선'));
    await tester.pumpAndSettle();

    expect(result, {'seoul-line2'});
  });
}
