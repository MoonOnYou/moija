import '../models/location_node.dart';
import 'subway_stations.dart';

/// 전국 시/도 + 시·군(도) / 지하철 호선·구(광역시) 카탈로그.
class LocationCatalog {
  static const List<String> regions = [
    '서울', '부산', '대구', '인천', '광주', '대전', '울산', '세종',
    '경기', '강원', '충북', '충남', '전북', '전남', '경북', '경남', '제주',
  ];

  /// 도(道)의 시·군 라벨 목록으로 `<도>-<라벨>` id의 노드를 만든다.
  static List<LocationNode> _province(String region, List<String> labels) => [
        for (final label in labels)
          LocationNode(id: '$region-$label', label: label, region: region),
      ];

  static final Map<String, List<LocationNode>> _byRegion = {
    '서울': const [
      LocationNode(id: 'seoul-line1', label: '1호선', region: '서울'),
      LocationNode(id: 'seoul-line2', label: '2호선', region: '서울'),
      LocationNode(id: 'seoul-line3', label: '3호선', region: '서울'),
      LocationNode(id: 'seoul-line4', label: '4호선', region: '서울'),
      LocationNode(id: 'seoul-line5', label: '5호선', region: '서울'),
      LocationNode(id: 'seoul-line6', label: '6호선', region: '서울'),
      LocationNode(id: 'seoul-line7', label: '7호선', region: '서울'),
      LocationNode(id: 'seoul-line8', label: '8호선', region: '서울'),
      LocationNode(id: 'seoul-line9', label: '9호선', region: '서울'),
      // 광역 노선(여러 시/도에 중복 노출)
      LocationNode(id: 'sinbundang', label: '신분당선', region: '서울'),
      LocationNode(id: 'suin-bundang', label: '수인분당선', region: '서울'),
      LocationNode(id: 'gyeongui-jungang', label: '경의중앙선', region: '서울'),
      LocationNode(id: 'gyeongchun', label: '경춘선', region: '서울'),
      LocationNode(id: 'airport', label: '공항철도', region: '서울'),
      LocationNode(id: 'ui-sinseol', label: '우이신설선', region: '서울'),
      LocationNode(id: 'sillim', label: '신림선', region: '서울'),
      LocationNode(id: 'gimpo-gold', label: '김포골드라인', region: '서울'),
      LocationNode(id: 'gtx-a', label: 'GTX-A', region: '서울'),
    ],
    '부산': const [
      LocationNode(id: 'busan-line1', label: '부산1호선', region: '부산'),
      LocationNode(id: 'busan-line2', label: '부산2호선', region: '부산'),
      LocationNode(id: 'busan-line3', label: '부산3호선', region: '부산'),
      LocationNode(id: 'busan-line4', label: '부산4호선', region: '부산'),
      // 광역 노선
      LocationNode(id: 'donghae', label: '동해선', region: '부산'),
      LocationNode(id: 'busan-gimhae', label: '부산김해경전철', region: '부산'),
    ],
    '대구': const [
      LocationNode(id: 'daegu-line1', label: '대구1호선', region: '대구'),
      LocationNode(id: 'daegu-line2', label: '대구2호선', region: '대구'),
      LocationNode(id: 'daegu-line3', label: '대구3호선', region: '대구'),
      LocationNode(id: 'daegyeong', label: '대경선', region: '대구'),
    ],
    '인천': const [
      LocationNode(id: 'incheon-line1', label: '인천1호선', region: '인천'),
      LocationNode(id: 'incheon-line2', label: '인천2호선', region: '인천'),
      // 광역 노선
      LocationNode(id: 'suin-bundang', label: '수인분당선', region: '인천'),
      LocationNode(id: 'airport', label: '공항철도', region: '인천'),
    ],
    '광주': const [
      LocationNode(id: 'gwangju-line1', label: '광주1호선', region: '광주'),
    ],
    '대전': const [
      LocationNode(id: 'daejeon-line1', label: '대전1호선', region: '대전'),
    ],
    '울산': const [
      LocationNode(id: 'ulsan-junggu', label: '중구', region: '울산'),
      LocationNode(id: 'ulsan-namgu', label: '남구', region: '울산'),
      LocationNode(id: 'ulsan-donggu', label: '동구', region: '울산'),
      LocationNode(id: 'ulsan-bukgu', label: '북구', region: '울산'),
      LocationNode(id: 'ulsan-uljugun', label: '울주군', region: '울산'),
      // 광역 노선
      LocationNode(id: 'donghae', label: '동해선', region: '울산'),
    ],
    '세종': const [
      LocationNode(id: 'sejong', label: '세종시 전체', region: '세종'),
    ],
    '경기': [
      ..._province('경기', const [
        '수원시', '성남시', '의정부시', '안양시', '부천시', '광명시', '평택시',
        '동두천시', '안산시', '고양시', '과천시', '구리시', '남양주시', '오산시',
        '시흥시', '군포시', '의왕시', '하남시', '용인시', '파주시', '이천시',
        '안성시', '김포시', '화성시', '광주시', '양주시', '포천시', '여주시',
        '연천군', '가평군', '양평군',
      ]),
      // 광역 노선(여러 시/도에 중복 노출)
      const LocationNode(id: 'sinbundang', label: '신분당선', region: '경기'),
      const LocationNode(id: 'suin-bundang', label: '수인분당선', region: '경기'),
      const LocationNode(id: 'gyeongui-jungang', label: '경의중앙선', region: '경기'),
      const LocationNode(id: 'gyeongchun', label: '경춘선', region: '경기'),
      const LocationNode(id: 'gimpo-gold', label: '김포골드라인', region: '경기'),
      const LocationNode(id: 'seohae', label: '서해선', region: '경기'),
      const LocationNode(id: 'gyeonggang', label: '경강선', region: '경기'),
      const LocationNode(id: 'uijeongbu-lrt', label: '의정부경전철', region: '경기'),
      const LocationNode(id: 'yongin-everline', label: '용인에버라인', region: '경기'),
      const LocationNode(id: 'gtx-a', label: 'GTX-A', region: '경기'),
    ],
    '강원': [
      ..._province('강원', const [
        '춘천시', '원주시', '강릉시', '동해시', '태백시', '속초시', '삼척시',
        '홍천군', '횡성군', '영월군', '평창군', '정선군', '철원군', '화천군',
        '양구군', '인제군', '고성군', '양양군',
      ]),
      // 광역 노선
      const LocationNode(id: 'gyeongchun', label: '경춘선', region: '강원'),
    ],
    '충북': _province('충북', const [
      '청주시', '충주시', '제천시', '보은군', '옥천군', '영동군', '증평군',
      '진천군', '괴산군', '음성군', '단양군',
    ]),
    '충남': _province('충남', const [
      '천안시', '공주시', '보령시', '아산시', '서산시', '논산시', '계룡시',
      '당진시', '금산군', '부여군', '서천군', '청양군', '홍성군', '예산군',
      '태안군',
    ]),
    '전북': _province('전북', const [
      '전주시', '군산시', '익산시', '정읍시', '남원시', '김제시', '완주군',
      '진안군', '무주군', '장수군', '임실군', '순창군', '고창군', '부안군',
    ]),
    '전남': _province('전남', const [
      '목포시', '여수시', '순천시', '나주시', '광양시', '담양군', '곡성군',
      '구례군', '고흥군', '보성군', '화순군', '장흥군', '강진군', '해남군',
      '영암군', '무안군', '함평군', '영광군', '장성군', '완도군', '진도군',
      '신안군',
    ]),
    '경북': [
      ..._province('경북', const [
        '포항시', '경주시', '김천시', '안동시', '구미시', '영주시', '영천시',
        '상주시', '문경시', '경산시', '의성군', '청송군', '영양군', '영덕군',
        '청도군', '고령군', '성주군', '칠곡군', '예천군', '봉화군', '울진군',
        '울릉군',
      ]),
      // 광역 노선
      const LocationNode(id: 'daegyeong', label: '대경선', region: '경북'),
    ],
    '경남': [
      ..._province('경남', const [
        '창원시', '진주시', '통영시', '사천시', '김해시', '밀양시', '거제시',
        '양산시', '의령군', '함안군', '창녕군', '고성군', '남해군', '하동군',
        '산청군', '함양군', '거창군', '합천군',
      ]),
      // 광역 노선
      const LocationNode(id: 'busan-gimhae', label: '부산김해경전철', region: '경남'),
    ],
    '제주': _province('제주', const ['제주시', '서귀포시']),
  };

  /// 노선 노드 id가 속한 시/도를 _byRegion에서만 찾는다(역 노드 초기화 전 호출 안전).
  static String _regionOfLineId(String lineId) {
    for (final entry in _byRegion.entries) {
      if (entry.value.any((n) => n.id == lineId)) return entry.key;
    }
    return '';
  }

  /// 노선 id → 역 노드 목록. kSubwayStations로부터 생성(지연 초기화).
  static final Map<String, List<LocationNode>> _stationsByLine = {
    for (final entry in kSubwayStations.entries)
      entry.key: [
        for (final name in entry.value)
          LocationNode(
            id: '${entry.key}-$name',
            label: name,
            region: _regionOfLineId(entry.key),
          ),
      ],
  };

  /// 노선이면 역 노드 목록, 아니면(시·군/구·미지정) 빈 목록.
  static List<LocationNode> childrenOf(String nodeId) =>
      _stationsByLine[nodeId] ?? const [];

  static List<LocationNode> nodesIn(String region) =>
      _byRegion[region] ?? const [];

  /// 시/도 이름인지 여부. 필터 id로 "서울"·"부산" 같은 region 자체가 들어올 수 있다.
  static bool isRegion(String id) => regions.contains(id);

  /// id가 속한 시/도 이름. region id면 그 자체, 노드면 node.region, 알 수 없으면 ''.
  static String regionOf(String id) {
    if (isRegion(id)) return id;
    return nodeById(id)?.region ?? '';
  }

  /// 필터 id 집합에 region 자체(예: "서울")가 있으면 그 region의 자식 노드 id로 펼친다.
  /// region이 아닌 id는 그대로 둔다.
  static Set<String> expandToLeafIds(Iterable<String> ids) {
    final out = <String>{};
    for (final id in ids) {
      if (isRegion(id)) {
        for (final n in nodesIn(id)) {
          out.add(n.id);
        }
      } else {
        out.add(id);
      }
    }
    return out;
  }

  static LocationNode? nodeById(String id) {
    for (final list in _byRegion.values) {
      for (final node in list) {
        if (node.id == id) return node;
      }
    }
    for (final stations in _stationsByLine.values) {
      for (final node in stations) {
        if (node.id == id) return node;
      }
    }
    return null;
  }

  /// 표시용 라벨. 역이면 노선명을 앞에 붙여 동명 역을 구분한다(예: "2호선 시청").
  static String displayLabel(String id) {
    if (isRegion(id)) return '$id 전체';
    final node = nodeById(id);
    if (node == null) return id;
    final dash = id.lastIndexOf('-');
    if (dash > 0) {
      final parentId = id.substring(0, dash);
      final line = nodeById(parentId);
      if (line != null && childrenOf(parentId).isNotEmpty) {
        return '${line.label} ${node.label}';
      }
    }
    return node.label;
  }
}
