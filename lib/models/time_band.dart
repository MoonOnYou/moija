/// 하루를 4개 시간대로 나눈다.
enum TimeBand {
  morning('오전', '00–12시', 0, 12),
  afternoon('오후', '12–17시', 12, 17),
  evening('저녁', '17–22시', 17, 22),
  night('밤', '22–24시', 22, 24);

  const TimeBand(this.label, this.range, this.startHour, this.endHour);

  final String label;
  final String range;
  final int startHour;
  final int endHour;

  /// [hour]가 이 시간대에 속하는지. (시작 포함, 끝 제외)
  bool containsHour(int hour) => hour >= startHour && hour < endHour;
}
