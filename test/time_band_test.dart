import 'package:flutter_test/flutter_test.dart';
import 'package:moija/models/time_band.dart';

void main() {
  test('containsHour boundaries', () {
    expect(TimeBand.morning.containsHour(6), isTrue);
    expect(TimeBand.morning.containsHour(5), isFalse);
    expect(TimeBand.morning.containsHour(12), isFalse);
    expect(TimeBand.afternoon.containsHour(12), isTrue);
    expect(TimeBand.afternoon.containsHour(18), isFalse);
    expect(TimeBand.evening.containsHour(18), isTrue);
    expect(TimeBand.evening.containsHour(21), isFalse);
    expect(TimeBand.night.containsHour(21), isTrue);
    expect(TimeBand.night.containsHour(23), isTrue);
  });

  test('labels and ranges', () {
    expect(TimeBand.morning.label, '오전');
    expect(TimeBand.afternoon.range, '12–18시');
  });
}
