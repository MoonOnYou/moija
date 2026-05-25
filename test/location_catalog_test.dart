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

  test('서울 has 9 numbered lines plus 광역 노선', () {
    final seoul = LocationCatalog.nodesIn('서울');
    expect(seoul.any((n) => n.id == 'seoul-line2'), isTrue);
    // 숫자 호선 9개 + 광역 노선
    expect(seoul.where((n) => n.id.startsWith('seoul-line')).length, 9);
    expect(seoul.map((n) => n.label),
        containsAll(['신림선', '경의중앙선', '신분당선', '공항철도']));
  });

  test('광역 노선은 걸치는 모든 시/도에 같은 id로 노출된다', () {
    bool hasLine(String region, String id) =>
        LocationCatalog.nodesIn(region).any((n) => n.id == id);
    // 경의중앙선: 서울·경기
    expect(hasLine('서울', 'gyeongui-jungang'), isTrue);
    expect(hasLine('경기', 'gyeongui-jungang'), isTrue);
    // 수인분당선: 서울·경기·인천
    expect(hasLine('서울', 'suin-bundang'), isTrue);
    expect(hasLine('경기', 'suin-bundang'), isTrue);
    expect(hasLine('인천', 'suin-bundang'), isTrue);
    // 동해선: 부산·울산 / 부산김해경전철: 부산·경남
    expect(hasLine('부산', 'donghae'), isTrue);
    expect(hasLine('울산', 'donghae'), isTrue);
    expect(hasLine('부산', 'busan-gimhae'), isTrue);
    expect(hasLine('경남', 'busan-gimhae'), isTrue);
    // 대경선: 대구·경북
    expect(hasLine('대구', 'daegyeong'), isTrue);
    expect(hasLine('경북', 'daegyeong'), isTrue);

    // 같은 id이므로 역 목록은 한 벌만 공유한다.
    expect(LocationCatalog.childrenOf('gyeongui-jungang'),
        LocationCatalog.childrenOf('gyeongui-jungang'));
    expect(LocationCatalog.childrenOf('gyeongui-jungang'), isNotEmpty);
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

  test('서울 외 광역시는 호선과 함께 구·군도 노출된다', () {
    bool hasNode(String region, String id) =>
        LocationCatalog.nodesIn(region).any((n) => n.id == id);

    expect(hasNode('부산', '부산-해운대구'), isTrue);
    expect(hasNode('부산', 'busan-line2'), isTrue);
    expect(hasNode('대구', '대구-수성구'), isTrue);
    expect(hasNode('대구', 'daegu-line2'), isTrue);
    expect(hasNode('인천', '인천-연수구'), isTrue);
    expect(hasNode('인천', 'incheon-line1'), isTrue);
    expect(hasNode('광주', '광주-동구'), isTrue);
    expect(hasNode('광주', 'gwangju-line1'), isTrue);
    expect(hasNode('대전', '대전-유성구'), isTrue);
    expect(hasNode('대전', 'daejeon-line1'), isTrue);
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

  test('childrenOf returns station nodes for a subway line', () {
    final stations = LocationCatalog.childrenOf('seoul-line2');
    expect(stations, isNotEmpty);
    expect(stations.any((n) => n.id == 'seoul-line2-강남'), isTrue);
    expect(stations.first.region, '서울');
  });

  test('childrenOf is empty for 시·군 leaves and unknown ids', () {
    expect(LocationCatalog.childrenOf('경기-수원시'), isEmpty);
    expect(LocationCatalog.childrenOf('nope'), isEmpty);
  });

  test('nodeById resolves a station node', () {
    final n = LocationCatalog.nodeById('seoul-line2-강남');
    expect(n?.label, '강남');
    expect(n?.region, '서울');
  });
}
