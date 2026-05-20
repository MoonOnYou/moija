/// 장소 트리의 리프 노드(지하철 호선/구/권역).
class LocationNode {
  const LocationNode({
    required this.id,
    required this.label,
    required this.region,
  });

  final String id;
  final String label;
  final String region;
}
