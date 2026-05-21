import 'package:flutter_test/flutter_test.dart';
import 'package:moija/data/subway_stations.dart';

void main() {
  test('서울 2호선은 강남·시청 포함, 40역 이상', () {
    final line2 = kSubwayStations['seoul-line2']!;
    expect(line2, contains('강남'));
    expect(line2, contains('시청'));
    expect(line2.length, greaterThan(40));
  });

  test('모든 광역시 노선 id 키가 존재한다', () {
    expect(
      kSubwayStations.keys,
      containsAll(<String>[
        'seoul-line1', 'seoul-line2', 'seoul-line3', 'seoul-line4',
        'seoul-line5', 'seoul-line6', 'seoul-line7', 'seoul-line8', 'seoul-line9',
        'busan-line1', 'busan-line2', 'busan-line3', 'busan-line4',
        'daegu-line1', 'daegu-line2', 'daegu-line3',
        'incheon-line1', 'incheon-line2',
        'gwangju-line1', 'daejeon-line1',
      ]),
    );
  });

  test('역 이름에는 매칭 구분자 - 가 없다', () {
    for (final stations in kSubwayStations.values) {
      for (final s in stations) {
        expect(s.contains('-'), isFalse, reason: '역명에 - 포함: $s');
      }
    }
  });
}
