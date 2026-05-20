/// [month]가 속한 달을 그리는 6주(42칸) 그리드를 생성한다.
/// 주 시작은 일요일. 앞뒤로 이웃 달 날짜가 채워진다.
/// 반환되는 각 DateTime은 시각이 00:00인 날짜 키다.
List<DateTime> buildMonthGrid(DateTime month) {
  final firstOfMonth = DateTime(month.year, month.month, 1);
  // Dart weekday: Mon=1..Sun=7. 일요일 시작이므로 Sun→0 으로 변환.
  final leading = firstOfMonth.weekday % 7;
  final start = firstOfMonth.subtract(Duration(days: leading));
  return List.generate(
    42,
    (i) => DateTime(start.year, start.month, start.day + i),
  );
}

/// 두 날짜가 같은 '날'(연/월/일)인지.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
