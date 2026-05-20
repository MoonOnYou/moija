import 'package:flutter_test/flutter_test.dart';
import 'package:moija/data/location_catalog.dart';

void main() {
  test('regions are the 17 시/도 in order', () {
    expect(LocationCatalog.regions.length, 17);
    expect(LocationCatalog.regions.first, '서울');
    expect(LocationCatalog.regions, contains('전북'));
    expect(LocationCatalog.regions, contains('전남'));
    expect(LocationCatalog.regions, contains('강원'));
    expect(LocationCatalog.regions, contains('경남'));
    expect(LocationCatalog.regions, contains('충북'));
    expect(LocationCatalog.regions, isNot(contains('전라')));
  });

  test('서울 has 9 subway lines', () {
    final seoul = LocationCatalog.nodesIn('서울');
    expect(seoul.length, 9);
    expect(seoul.any((n) => n.id == 'seoul-line2'), isTrue);
  });

  test('제주 has 2 cities', () {
    final jeju = LocationCatalog.nodesIn('제주');
    expect(jeju.length, 2);
    expect(jeju.map((n) => n.label), containsAll(['제주시', '서귀포시']));
  });

  test('경기 includes all listed 시·군', () {
    final gg = LocationCatalog.nodesIn('경기');
    expect(gg.length, greaterThanOrEqualTo(31));
    expect(gg.map((n) => n.label), containsAll(['수원시', '양평군']));
  });

  test('울산 uses 구/군 (no subway)', () {
    final ulsan = LocationCatalog.nodesIn('울산');
    expect(ulsan.map((n) => n.label), containsAll(['중구', '울주군']));
  });

  test('nodeById resolves labels', () {
    expect(LocationCatalog.nodeById('seoul-line2')?.label, '2호선');
    expect(LocationCatalog.nodeById('busan-line4')?.label, '부산4호선');
    expect(LocationCatalog.nodeById('경기-수원시')?.label, '수원시');
    expect(LocationCatalog.nodeById('nope'), isNull);
  });

  test('same 군 name in different 도 are distinct nodes', () {
    final gangwon = LocationCatalog.nodeById('강원-고성군');
    final gyeongnam = LocationCatalog.nodeById('경남-고성군');
    expect(gangwon?.region, '강원');
    expect(gyeongnam?.region, '경남');
  });
}
