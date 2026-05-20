/// 모임 비용 부담 방식.
enum CostType {
  split('더치페이'),
  hostPays('호스트가 쏨'),
  free('무료'),
  paid('유료');

  const CostType(this.label);
  final String label;
}

class MeetingCost {
  const MeetingCost(this.type, {this.amountWon});

  final CostType type;
  final int? amountWon;

  /// 유료면 천단위 콤마 금액, 그 외엔 유형 라벨.
  String get display {
    if (type == CostType.paid && amountWon != null) {
      final s = amountWon.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return '$buf원';
    }
    return type.label;
  }
}
