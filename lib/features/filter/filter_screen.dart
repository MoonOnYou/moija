import 'package:flutter/material.dart';
import '../../data/category_catalog.dart';
import '../../data/location_catalog.dart';
import '../../models/meeting_category.dart';
import '../../models/meeting_filter.dart';
import '../../models/time_band.dart';
import '../../theme/app_colors.dart';
import 'category_browser_screen.dart';
import 'location_picker_screen.dart';

/// 카테고리·장소·시간대 필터 화면. 저장 시 MeetingFilter를 pop으로 반환.
class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key, required this.initial});

  final MeetingFilter initial;

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late final Set<MeetingCategory> _categories = {...widget.initial.categories};
  late final Set<String> _locationIds = {...widget.initial.locationIds};
  late final Set<TimeBand> _timeBands = {...widget.initial.timeBands};
  late final Set<String> _customCategories = {...widget.initial.customCategories};

  void _reset() {
    setState(() {
      _categories.clear();
      _locationIds.clear();
      _timeBands.clear();
      _customCategories.clear();
    });
  }

  void _save() {
    Navigator.pop(
      context,
      MeetingFilter(
        categories: {..._categories},
        locationIds: {..._locationIds},
        timeBands: {..._timeBands},
        customCategories: {..._customCategories},
      ),
    );
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initial: _locationIds),
      ),
    );
    if (result != null) {
      setState(() {
        _locationIds
          ..clear()
          ..addAll(result);
      });
    }
  }

  /// 전체보기 화면으로 들어가 모든 서브 라벨 중에서 다중 선택을 받는다.
  /// 라벨이 enum에 매핑되면 _categories에, 안 되면 _customCategories에 들어간다.
  Future<void> _openCategoryBrowser() async {
    final initial = <String>{
      ..._categories.map((c) => c.label),
      ..._customCategories,
    };
    final result = await Navigator.push<Object>(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryBrowserScreen(initial: initial),
      ),
    );
    if (result is! Set<String>) return;
    if (!mounted) return;
    setState(() {
      _categories.clear();
      _customCategories.clear();
      for (final label in result) {
        final c = CategoryCatalog.categoryFor(label);
        if (c == MeetingCategory.etc && label != '기타') {
          _customCategories.add(label);
        } else {
          _categories.add(c);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('필터'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('카테고리 (여러 개 선택)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in CategoryCatalog.mainShortcuts)
                _chip(
                  c.label,
                  _categories.contains(c),
                  () => setState(() {
                    if (!_categories.add(c)) _categories.remove(c);
                  }),
                ),
              // 전체보기에서 enum 매핑된 것 외에 추가된 라벨은 그대로 칩으로 노출.
              for (final custom in _customCategories)
                _chip(custom, true,
                    () => setState(() => _customCategories.remove(custom))),
              _browserChip(),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('장소'),
          GestureDetector(
            onTap: _openLocationPicker,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderTertiary),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _locationIds.isEmpty
                          ? '지역 선택'
                          : _locationIds
                              .map(LocationCatalog.displayLabel)
                              .join(', '),
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('시간대 (여러 개 선택)'),
          Row(
            children: [
              for (final b in TimeBand.values) ...[
                Expanded(child: _timeChip(b)),
                if (b != TimeBand.night) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('초기화'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.bgPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('저장하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      );

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.textInfo : AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          selected ? '$label ✓' : label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _browserChip() {
    return GestureDetector(
      key: const Key('category-browser-open'),
      onTap: _openCategoryBrowser,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderTertiary, width: 0.5),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grid_view_rounded,
                size: 13, color: AppColors.textSecondary),
            SizedBox(width: 4),
            Text('전체보기',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _timeChip(TimeBand band) {
    final selected = _timeBands.contains(band);
    return GestureDetector(
      onTap: () => setState(() {
        if (!_timeBands.add(band)) _timeBands.remove(band);
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.textInfo : AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(band.label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(band.range,
                style: TextStyle(
                    fontSize: 10,
                    color: selected ? Colors.white70 : AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}
