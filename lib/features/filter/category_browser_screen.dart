import 'package:flutter/material.dart';
import '../../data/category_catalog.dart';
import '../../theme/app_colors.dart';


/// 전체 카테고리 풀스크린. 그룹별 헤더 + 서브 라벨 칩을 보여주고,
/// 다중 선택(필터)에서는 [Navigator.pop]에 `Set<String>` 라벨 집합을,
/// 단일 선택(모임 만들기)에서는 탭한 단일 라벨(String)을 반환한다.
class CategoryBrowserScreen extends StatefulWidget {
  const CategoryBrowserScreen({
    super.key,
    this.initial = const <String>{},
    this.singleSelect = false,
  });

  final Set<String> initial;
  final bool singleSelect;

  @override
  State<CategoryBrowserScreen> createState() => _CategoryBrowserScreenState();
}

class _CategoryBrowserScreenState extends State<CategoryBrowserScreen> {
  late final Set<String> _selected = {...widget.initial};

  void _toggle(String label) {
    setState(() {
      if (!_selected.add(label)) _selected.remove(label);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        title: const Text('전체 카테고리',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          for (final group in CategoryCatalog.groups) ...[
            _GroupHeader(title: group.title, icon: group.icon),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final label in group.items)
                    _CategoryChip(
                      label: label,
                      selected: _selected.contains(label),
                      onTap: () {
                        if (widget.singleSelect) {
                          Navigator.of(context).pop(label);
                        } else {
                          _toggle(label);
                        }
                      },
                    ),
                ],
              ),
            ),
          ],
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
                    key: const Key('category-browser-done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      foregroundColor: AppColors.bgPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => Navigator.of(context).pop(_selected),
                    child: Text(_selected.isEmpty
                        ? '완료'
                        : '${_selected.length}개 적용'),
                  ),
                ),
              ),
            ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.coral),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 그룹별로 색이 다르면 산만하므로 모든 칩은 동일 톤을 쓰고,
    // 선택 여부만 색으로 구분한다. 필터·모임 만들기의 메인 칩과도 일관.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color:
                selected ? AppColors.textPrimary : AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.textPrimary
                  : AppColors.borderTertiary,
              width: selected ? 1.0 : 0.5,
            ),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textPrimary)),
        ),
      ),
    );
  }
}
