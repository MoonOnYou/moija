import 'package:flutter_test/flutter_test.dart';
import 'package:moija/models/join_method.dart';

void main() {
  test('승인제/선착순 라벨·요약·불릿', () {
    expect(JoinMethod.approval.label, '승인제');
    expect(JoinMethod.approval.summary, '신청을 받고 멤버를 골라 수락해요');
    expect(JoinMethod.approval.bullets, [
      '누가 오는지 보고 결정',
      '신청자는 수락될 때만 다이아 차감',
    ]);
    expect(JoinMethod.firstCome.label, '선착순');
    expect(JoinMethod.firstCome.summary, '자리가 있으면 바로 확정돼요');
    expect(JoinMethod.firstCome.bullets, [
      '빠르게 모으고 싶을 때',
      '신청 즉시 확정 + 다이아 차감',
    ]);
  });
}
