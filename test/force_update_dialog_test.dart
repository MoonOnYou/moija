import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moija/features/common/force_update_dialog.dart';

void main() {
  testWidgets('다이얼로그에 제목·버전·업데이트 버튼이 노출된다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => ForceUpdateDialog.show(
                  ctx,
                  currentVersion: '1.0.0',
                  latestVersion: '1.2.0',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('새 버전이 출시되었어요'), findsOneWidget);
    expect(find.textContaining('업데이트가 필요해요'), findsOneWidget);
    expect(find.textContaining('현재 1.0.0'), findsOneWidget);
    expect(find.textContaining('최신 1.2.0'), findsOneWidget);
    expect(find.byKey(const Key('force-update-button')), findsOneWidget);
  });

  testWidgets('barrier 탭으로는 닫히지 않는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => ForceUpdateDialog.show(ctx),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // barrier 영역(좌상단 가장자리)을 탭해도 다이얼로그가 유지된다.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('새 버전이 출시되었어요'), findsOneWidget);
  });

  testWidgets('"지금 업데이트" 버튼은 다이얼로그를 닫는다(출시 전 mock)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => ForceUpdateDialog.show(ctx),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('새 버전이 출시되었어요'), findsOneWidget);

    await tester.tap(find.byKey(const Key('force-update-button')));
    await tester.pumpAndSettle();
    expect(find.text('새 버전이 출시되었어요'), findsNothing);
  });

  testWidgets('뒤로가기 시스템 호출에도 닫히지 않는다(PopScope)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => ForceUpdateDialog.show(ctx),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('새 버전이 출시되었어요'), findsOneWidget);
  });
}
