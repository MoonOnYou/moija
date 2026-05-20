import 'package:flutter_test/flutter_test.dart';
import 'package:moija/models/meeting_cost.dart';

void main() {
  test('paid shows comma-formatted amount', () {
    expect(const MeetingCost(CostType.paid, amountWon: 10000).display, '10,000원');
  });
  test('non-paid shows the type label', () {
    expect(const MeetingCost(CostType.split).display, '더치페이');
    expect(const MeetingCost(CostType.free).display, '무료');
    expect(const MeetingCost(CostType.hostPays).display, '호스트가 쏨');
  });
}
