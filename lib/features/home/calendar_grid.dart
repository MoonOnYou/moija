/// [day]가 속한 주의 일요일(00:00)을 반환한다.
/// Dart weekday: Mon=1..Sun=7. 일요일 시작이므로 Sun→0 으로 변환.
DateTime weekStartOf(DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  return d.subtract(Duration(days: d.weekday % 7));
}

/// [weekStart](일요일)부터 14일(2주) 그리드를 생성한다.
/// 반환되는 각 DateTime은 시각이 00:00인 날짜 키다.
List<DateTime> twoWeekGridFrom(DateTime weekStart) {
  final s = DateTime(weekStart.year, weekStart.month, weekStart.day);
  return List.generate(
    14,
    (i) => DateTime(s.year, s.month, s.day + i),
  );
}

/// 오늘이 포함된 주를 첫째 줄로 하는 2주 그리드.
List<DateTime> buildTwoWeekGrid(DateTime today) =>
    twoWeekGridFrom(weekStartOf(today));

/// 두 날짜가 같은 '날'(연/월/일)인지.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
