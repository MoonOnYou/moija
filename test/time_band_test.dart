import 'package:flutter_test/flutter_test.dart';
import 'package:moija/models/time_band.dart';

void main() {
  test('containsHour boundaries', () {
    // 오전 0~12시
    expect(TimeBand.morning.containsHour(0), isTrue);
    expect(TimeBand.morning.containsHour(5), isTrue);
    expect(TimeBand.morning.containsHour(12), isFalse);
    // 오후 12~17시
    expect(TimeBand.afternoon.containsHour(12), isTrue);
    expect(TimeBand.afternoon.containsHour(16), isTrue);
    expect(TimeBand.afternoon.containsHour(17), isFalse);
    // 저녁 17~22시
    expect(TimeBand.evening.containsHour(17), isTrue);
    expect(TimeBand.evening.containsHour(21), isTrue);
    expect(TimeBand.evening.containsHour(22), isFalse);
    // 밤 22~24시
    expect(TimeBand.night.containsHour(21), isFalse);
    expect(TimeBand.night.containsHour(22), isTrue);
    expect(TimeBand.night.containsHour(23), isTrue);
  });

  test('labels and ranges', () {
    expect(TimeBand.morning.label, '오전');
    expect(TimeBand.morning.range, '00–12시');
    expect(TimeBand.afternoon.range, '12–17시');
    expect(TimeBand.evening.range, '17–22시');
    expect(TimeBand.night.range, '22–24시');
  });
}
