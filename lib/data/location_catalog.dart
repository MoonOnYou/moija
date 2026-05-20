import '../models/location_node.dart';

/// 대표 서브셋 장소 카탈로그(하드코딩). 전국 전수 데이터는 범위 밖.
class LocationCatalog {
  static const List<String> regions = [
    '서울', '경기', '인천', '대전', '대구', '부산', '광주', '전라',
  ];

  static const Map<String, List<LocationNode>> _byRegion = {
    '서울': [
      LocationNode(id: 'seoul-line1', label: '1호선', region: '서울'),
      LocationNode(id: 'seoul-line2', label: '2호선', region: '서울'),
      LocationNode(id: 'seoul-line3', label: '3호선', region: '서울'),
      LocationNode(id: 'seoul-line4', label: '4호선', region: '서울'),
      LocationNode(id: 'seoul-line5', label: '5호선', region: '서울'),
      LocationNode(id: 'seoul-line6', label: '6호선', region: '서울'),
      LocationNode(id: 'seoul-line7', label: '7호선', region: '서울'),
      LocationNode(id: 'seoul-line8', label: '8호선', region: '서울'),
      LocationNode(id: 'seoul-line9', label: '9호선', region: '서울'),
    ],
    '경기': [
      LocationNode(id: 'gg-suwon', label: '수원시', region: '경기'),
      LocationNode(id: 'gg-seongnam', label: '성남시', region: '경기'),
      LocationNode(id: 'gg-goyang', label: '고양시', region: '경기'),
      LocationNode(id: 'gg-yongin', label: '용인시', region: '경기'),
    ],
    '인천': [
      LocationNode(id: 'incheon-line1', label: '인천1호선', region: '인천'),
      LocationNode(id: 'incheon-line2', label: '인천2호선', region: '인천'),
    ],
    '대전': [
      LocationNode(id: 'daejeon-line1', label: '대전1호선', region: '대전'),
    ],
    '대구': [
      LocationNode(id: 'daegu-line1', label: '대구1호선', region: '대구'),
      LocationNode(id: 'daegu-line2', label: '대구2호선', region: '대구'),
    ],
    '부산': [
      LocationNode(id: 'busan-line1', label: '부산1호선', region: '부산'),
      LocationNode(id: 'busan-line2', label: '부산2호선', region: '부산'),
    ],
    '광주': [
      LocationNode(id: 'gwangju-line1', label: '광주1호선', region: '광주'),
    ],
    '전라': [
      LocationNode(id: 'jeolla-jeonju', label: '전주권', region: '전라'),
      LocationNode(id: 'jeolla-yeosuncheon', label: '여수·순천권', region: '전라'),
    ],
  };

  static List<LocationNode> nodesIn(String region) =>
      _byRegion[region] ?? const [];

  static LocationNode? nodeById(String id) {
    for (final list in _byRegion.values) {
      for (final node in list) {
        if (node.id == id) return node;
      }
    }
    return null;
  }
}
