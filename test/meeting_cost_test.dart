import 'package:flutter_test/flutter_test.dart';
import 'package:moija/models/meeting_cost.dart';

void main() {
  test('paid shows comma-formatted amount', () {
    expect(const MeetingCost(CostType.paid, amountWon: 10000).display, '10,000원');
  });
  test('non-paid shows the type label', () {
    expect(const MeetingCost(CostType.split).display, '더치페이');
    expect(const MeetingCost(CostType.eachPays).display, '각자계산');
    expect(const MeetingCost(CostType.free).display, '무료');
    expect(const MeetingCost(CostType.hostPays).display, '방장이 쏨');
  });
  test('custom shows entered text, falls back to label when empty', () {
    expect(const MeetingCost(CostType.custom, customText: '연구실에서 갹출').display,
        '연구실에서 갹출');
    expect(const MeetingCost(CostType.custom).display, '기타');
  });
}
