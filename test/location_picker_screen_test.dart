import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/features/filter/location_picker_screen.dart';

void main() {
  testWidgets('다중: 서울 → 2호선 드릴 → 시청 체크 → 완료 시 역 id 반환',
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
    await tester.tap(find.text('2호선')); // 드릴다운
    await tester.pumpAndSettle();
    await tester.tap(find.text('시청')); // 역 체크
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    expect(result, contains('seoul-line2-시청'));
  });

  testWidgets('다중: 2호선 전체 체크 시 노선 id 반환', (tester) async {
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
    await tester.tap(find.text('2호선 전체'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    expect(result, contains('seoul-line2'));
  });

  testWidgets('다중: 초기 선택 유지하며 누적', (tester) async {
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
    await tester.tap(find.text('2호선 전체'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    expect(result, containsAll(<String>['seoul-line1', 'seoul-line2']));
  });

  testWidgets('시스템 back: 역 화면 → 노선 목록 → 시/도 목록', (tester) async {
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

    await tester.tap(find.text('서울'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2호선'));
    await tester.pumpAndSettle();
    expect(find.text('시청'), findsOneWidget); // 역 화면

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('시청'), findsNothing);
    expect(find.text('9호선'), findsOneWidget); // 노선 목록

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('9호선'), findsNothing);
    expect(find.text('장소 선택'), findsOneWidget); // 시/도 목록
  });

  testWidgets('singleSelect: 서울 → 2호선 → 시청 탭 시 즉시 역 id pop',
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
    await tester.tap(find.text('2호선'));
    await tester.pumpAndSettle();
    expect(find.text('완료'), findsNothing); // 단일 모드엔 완료 버튼 없음
    await tester.tap(find.text('시청'));
    await tester.pumpAndSettle();

    expect(result, {'seoul-line2-시청'});
  });

  testWidgets('singleSelect: 시·군 리프(경기 → 수원시)는 바로 pop', (tester) async {
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

    await tester.tap(find.text('경기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수원시'));
    await tester.pumpAndSettle();

    expect(result, {'경기-수원시'});
  });

  testWidgets('다중: 목록 하단 역(충정로)도 스크롤하여 선택 가능', (tester) async {
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

    await tester.scrollUntilVisible(find.text('충정로'), 300.0);
    await tester.pumpAndSettle();
    await tester.tap(find.text('충정로'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    expect(result, contains('seoul-line2-충정로'));
  });
}
