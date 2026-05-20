import 'package:flutter/material.dart';
import '../../data/location_catalog.dart';
import '../../theme/app_colors.dart';

/// 시/도 목록 ↔ 지역 상세(리프 다중 체크) 드릴다운. 완료 시 선택 id 집합 반환.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, required this.initial});

  final Set<String> initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final Set<String> _selected = {...widget.initial};
  String? _region; // null = 시/도 목록, else 해당 지역 상세

  void _toggle(String id) {
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_region != null) {
          setState(() => _region = null);
        } else {
          Navigator.pop(context, _selected);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.bgPrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_region != null) {
                setState(() => _region = null);
              } else {
                Navigator.pop(context, _selected);
              }
            },
          ),
          title: Text(_region ?? '장소 선택'),
        ),
        body: Column(
          children: [
            if (_selected.isNotEmpty) _selectedChips(),
            Expanded(
                child: _region == null ? _regionList() : _nodeList(_region!)),
          ],
        ),
        bottomNavigationBar: SafeArea(
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
            trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
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
          CheckboxListTile(
            value: _selected.contains(node.id),
            title: Text(node.label),
            controlAffinity: ListTileControlAffinity.trailing,
            onChanged: (_) => _toggle(node.id),
          ),
      ],
    );
  }
}
