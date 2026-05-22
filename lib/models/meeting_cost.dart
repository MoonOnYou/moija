/// 모임 비용 부담 방식.
enum CostType {
  split('더치페이'),
  eachPays('각자계산'),
  hostPays('방장이 쏨'),
  free('무료'),
  paid('유료'),
  custom('기타');

  const CostType(this.label);
  final String label;
}

class MeetingCost {
  const MeetingCost(this.type, {this.amountWon, this.customText});

  final CostType type;
  final int? amountWon;

  /// 기타(custom) 비용으로 직접 입력한 문구.
  final String? customText;

  /// 유료면 천단위 콤마 금액, 기타면 입력 문구, 그 외엔 유형 라벨.
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
    if (type == CostType.custom &&
        customText != null &&
        customText!.isNotEmpty) {
      return customText!;
    }
    return type.label;
  }
}
