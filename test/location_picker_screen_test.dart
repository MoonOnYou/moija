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
    expect(find.text('서울 전체'), findsOneWidget); // 노선 목록 최상단

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('서울 전체'), findsNothing);
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

  testWidgets('singleSelect: "2호선 전체" 탭하면 노선 id로 즉시 pop', (tester) async {
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

    expect(find.text('2호선 전체'), findsOneWidget); // 노선 단위 선택 가능
    await tester.tap(find.text('2호선 전체'));
    await tester.pumpAndSettle();

    expect(result, {'seoul-line2'});
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

  testWidgets('다중: "서울 전체" 행 체크 후 완료 시 region id 반환', (tester) async {
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
    // 호선 목록 맨 위에 "서울 전체" 행이 노출되어야 한다.
    expect(find.text('서울 전체'), findsOneWidget);
    await tester.tap(find.text('서울 전체'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    expect(result, contains('서울'));
  });

  testWidgets('singleSelect: "경기 전체"를 누르면 region id로 즉시 pop', (tester) async {
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
    await tester.tap(find.text('경기 전체'));
    await tester.pumpAndSettle();

    expect(result, {'경기'});
  });

  testWidgets('세종은 단일 노드가 "세종시 전체"로 노출되고 region 전체 행은 없다',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push<Set<String>>(
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

    await tester.tap(find.text('세종'));
    await tester.pumpAndSettle();

    expect(find.text('세종시 전체'), findsOneWidget);
    expect(find.text('세종 전체'), findsNothing); // region 전체 행 없음
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
