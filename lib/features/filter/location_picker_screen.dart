import 'package:flutter/material.dart';
import '../../data/location_catalog.dart';
import '../../models/location_node.dart';
import '../../theme/app_colors.dart';

/// 시/도 → 노선/리프 → 역 3단계 드릴다운. 완료 시 선택 id 집합 반환.
/// [singleSelect]가 true이면 리프(역·시·군) 탭 즉시 단일 id로 pop.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    required this.initial,
    this.singleSelect = false,
  });

  final Set<String> initial;
  final bool singleSelect;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final Set<String> _selected = {...widget.initial};
  String? _region; // null = 시/도 목록
  LocationNode? _line; // null이 아니면 해당 노선의 역 목록

  void _toggle(String id) {
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  void _back() {
    if (_line != null) {
      setState(() => _line = null);
    } else if (_region != null) {
      setState(() => _region = null);
    } else {
      Navigator.pop(context, _selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = _line != null
        ? _stationList(_line!)
        : (_region == null ? _regionList() : _nodeList(_region!));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.bgPrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _back,
          ),
          title: Text(_line?.label ?? _region ?? '장소 선택'),
        ),
        body: Column(
          children: [
            if (!widget.singleSelect && _selected.isNotEmpty) _selectedChips(),
            Expanded(child: content),
          ],
        ),
        bottomNavigationBar: widget.singleSelect
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: AppColors.bgPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context, _selected),
                      child: const Text('완료'),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _selectedChips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderTertiary, width: 0.5),
        ),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final id in _selected)
            GestureDetector(
              onTap: () => _toggle(id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.textInfo,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${LocationCatalog.nodeById(id)?.label ?? id} ✕',
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _regionList() {
    return ListView(
      children: [
        for (final region in LocationCatalog.regions)
          ListTile(
            title: Text(region),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            onTap: () => setState(() => _region = region),
          ),
      ],
    );
  }

  Widget _nodeList(String region) {
    final nodes = LocationCatalog.nodesIn(region);
    return ListView(
      children: [
        for (final node in nodes)
          if (LocationCatalog.childrenOf(node.id).isNotEmpty)
            ListTile(
              title: Text(node.label),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textTertiary),
              onTap: () => setState(() => _line = node),
            )
          else if (widget.singleSelect)
            ListTile(
              title: Text(node.label),
              onTap: () => Navigator.pop(context, {node.id}),
            )
          else
            CheckboxListTile(
              value: _selected.contains(node.id),
              title: Text(node.label),
              controlAffinity: ListTileControlAffinity.trailing,
              onChanged: (_) => _toggle(node.id),
            ),
      ],
    );
  }

  Widget _stationList(LocationNode line) {
    final stations = LocationCatalog.childrenOf(line.id);
    Widget tile(String id, String label) => widget.singleSelect
        ? ListTile(
            title: Text(label),
            onTap: () => Navigator.pop(context, {id}),
          )
        : CheckboxListTile(
            value: _selected.contains(id),
            title: Text(label),
            controlAffinity: ListTileControlAffinity.trailing,
            onChanged: (_) => _toggle(id),
          );
    return ListView(
      children: [
        tile(line.id, '${line.label} 전체'),
        for (final s in stations) tile(s.id, s.label),
      ],
    );
  }
}