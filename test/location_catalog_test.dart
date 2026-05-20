import 'package:flutter_test/flutter_test.dart';
import 'package:moija/data/location_catalog.dart';

void main() {
  test('regions are the 8 시/도 in order', () {
    expect(LocationCatalog.regions.first, '서울');
    expect(LocationCatalog.regions.length, 8);
  });

  test('서울 has 9 subway lines', () {
    final seoul = LocationCatalog.nodesIn('서울');
    expect(seoul.length, 9);
    expect(seoul.any((n) => n.id == 'seoul-line2'), isTrue);
  });

  test('전라 is grouped into 2 권역', () {
    expect(LocationCatalog.nodesIn('전라').length, 2);
  });

  test('nodeById resolves label', () {
    expect(LocationCatalog.nodeById('seoul-line2')?.label, '2호선');
    expect(LocationCatalog.nodeById('nope'), isNull);
  });
}
