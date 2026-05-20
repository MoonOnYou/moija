/// 하루를 4개 시간대로 나눈다.
enum TimeBand {
  morning('오전', '06–12시', 6, 12),
  afternoon('오후', '12–18시', 12, 18),
  evening('저녁', '18–21시', 18, 21),
  night('밤', '21–24시', 21, 24);

  const TimeBand(this.label, this.range, this.startHour, this.endHour);

  final String label;
  final String range;
  final int startHour;
  final int endHour;

  /// [hour]가 이 시간대에 속하는지. (시작 포함, 끝 제외)
  bool containsHour(int hour) => hour >= startHour && hour < endHour;
}
