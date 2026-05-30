import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/category_catalog.dart';
import '../../data/location_catalog.dart';
import '../../data/api/meeting_api.dart';
import '../../data/wallet.dart';
import '../../models/join_method.dart';
import '../../models/meeting.dart';
import '../../models/meeting_category.dart';
import '../../models/meeting_cost.dart';
import '../../shell/app_navigation.dart';
import '../../theme/app_colors.dart';
import '../common/notice_screen.dart';
import '../filter/category_browser_screen.dart';
import '../filter/location_picker_screen.dart';
import 'diamond_recharge_screen.dart';

const int _createCost = 300;

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({
    super.key,
    this.currentDiamonds = Wallet.myDiamonds,
    @visibleForTesting this.onCreateMeeting,
  });

  final int currentDiamonds;
  @visibleForTesting
  final Future<void> Function(Meeting)? onCreateMeeting;

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  MeetingCategory? _category;
  /// 직접 입력한 카테고리. 값이 있으면 _category는 etc로 둔다.
  String? _customCategory;
  final _title = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  bool _online = false;
  String? _locationId;
  final _place = TextEditingController();
  final _placeFocus = FocusNode();
  int _members = 4;
  final _membersCtrl = TextEditingController(text: '4');
  CostType? _costType;
  final _amount = TextEditingController();
  final _costEtc = TextEditingController();
  final _description = TextEditingController();
  JoinMethod _joinMethod = JoinMethod.approval;
  bool _loading = false;

  static const _maxMembers = 99;
  static const _minMembers = 2;

  @override
  void initState() {
    super.initState();
    _title.addListener(_refresh);
    _place.addListener(_refresh);
    _amount.addListener(_refresh);
    _costEtc.addListener(_refresh);
  }

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    _placeFocus.dispose();
    _amount.dispose();
    _costEtc.dispose();
    _membersCtrl.dispose();
    _description.dispose();
    super.dispose();
  }

  /// 버튼으로 인원 증감(2~99로 클램프, 텍스트 필드도 동기화).
  void _setMembers(int v) {
    final clamped = v.clamp(_minMembers, _maxMembers);
    setState(() {
      _members = clamped;
      _membersCtrl.text = '$clamped';
    });
  }

  /// 인원 직접 입력. 99 초과면 99로 잘라준다. 빈 값은 0(미충족) 처리.
  void _onMembersTyped(String s) {
    final n = int.tryParse(s);
    if (n == null) {
      setState(() => _members = 0);
      return;
    }
    if (n > _maxMembers) {
      _membersCtrl.text = '$_maxMembers';
      _membersCtrl.selection =
          TextSelection.collapsed(offset: _membersCtrl.text.length);
      setState(() => _members = _maxMembers);
      return;
    }
    setState(() => _members = n);
  }

  MeetingCost _buildCost() {
    switch (_costType!) {
      case CostType.paid:
        return MeetingCost(CostType.paid,
            amountWon: int.tryParse(_amount.text.trim()));
      case CostType.custom:
        return MeetingCost(CostType.custom, customText: _costEtc.text.trim());
      default:
        return MeetingCost(_costType!);
    }
  }

  void _refresh() => setState(() {});

  bool get _valid {
    if (_category == null) return false;
    if (_title.text.trim().isEmpty) return false;
    if (_date == null || _time == null) return false;
    if (!_online && _locationId == null) return false;
    if (!_online && _place.text.trim().isEmpty) return false;
    if (_members < _minMembers || _members > _maxMembers) return false;
    if (_costType == null) return false;
    if (_costType == CostType.paid &&
        (int.tryParse(_amount.text.trim()) ?? 0) <= 0) {
      return false;
    }
    if (_costType == CostType.custom && _costEtc.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _pickDate() async {
    // 피커를 열기 전에 입력 포커스를 거둔다.
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 오늘로부터 50일까지만 모임 날짜로 선택할 수 있다.
    final lastDate = today.add(const Duration(days: 50));
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: today,
      lastDate: lastDate,
    );
    if (picked != null) setState(() => _date = picked);
    _dismissKeyboard();
  }

  Future<void> _pickTime() async {
    FocusScope.of(context).unfocus();
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 19, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
    _dismissKeyboard();
  }

  /// 피커가 닫히면 Flutter가 직전 텍스트필드로 포커스를 복원해 키보드가 다시
  /// 올라온다. 닫힌 직후와 다음 프레임에 포커스를 거둬 키보드를 내린다.
  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initial: _locationId == null ? <String>{} : {_locationId!},
          singleSelect: true,
        ),
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _locationId = result.first);
      // 장소를 고르면 곧바로 구체적 장소 입력으로 커서를 옮긴다. 피커가 닫히며
      // 포커스 복원이 끝난 뒤 잡도록 다음 프레임에 요청한다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _placeFocus.requestFocus();
      });
    }
  }

  /// 전체보기에서 라벨 하나를 골라온다. enum에 매핑되면 그 enum으로,
  /// 매핑이 없으면 etc + customCategory에 라벨을 저장한다.
  Future<void> _openCategoryBrowser() async {
    final initial = <String>{
      if (_customCategory != null && _customCategory!.isNotEmpty)
        _customCategory!
      else if (_category != null)
        _category!.label,
    };
    final result = await Navigator.push<Object>(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryBrowserScreen(
          initial: initial,
          singleSelect: true,
        ),
      ),
    );
    if (result is! String) return;
    if (!mounted) return;
    final mapped = CategoryCatalog.categoryFor(result);
    setState(() {
      if (mapped == MeetingCategory.etc && result != '기타') {
        _category = MeetingCategory.etc;
        _customCategory = result;
      } else {
        _category = mapped;
        _customCategory = null;
      }
    });
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (widget.currentDiamonds < _createCost) {
      messenger.showSnackBar(const SnackBar(content: Text('다이아가 부족해요')));
      navigator.push(
        MaterialPageRoute(
          builder: (_) =>
              DiamondRechargeScreen(currentDiamonds: widget.currentDiamonds),
        ),
      );
      return;
    }
    final agreed = await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => Notices.createMeeting()),
    );
    if (agreed != true || !mounted) return;
    final start = DateTime(
        _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    final placeText = _place.text.trim();
    final locLabel =
        _online ? '' : LocationCatalog.displayLabel(_locationId!);
    final regionName =
        _online ? '온라인' : LocationCatalog.regionOf(_locationId!);
    final meeting = Meeting(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      title: _title.text.trim(),
      category: _category!,
      customCategory: _customCategory ?? '',
      customIcon: (_customCategory != null && _customCategory!.isNotEmpty)
          ? CategoryCatalog.iconForLabel(_customCategory!)
          : null,
      startTime: start,
      location: _online
          ? (placeText.isEmpty ? '온라인' : placeText)
          : (placeText.isEmpty ? locLabel : placeText),
      region: _online
          ? '온라인'
          : (placeText.isNotEmpty ? placeText : regionName),
      locationId: _online ? 'online' : _locationId!,
      currentMembers: 1,
      maxMembers: _members,
      description: _description.text.trim(),
      nearestStation: _online ? '온라인' : locLabel,
      cost: _buildCost(),
      joinMethod: _joinMethod,
    );
    setState(() => _loading = true);
    try {
      await (widget.onCreateMeeting ?? createMeeting)(meeting);
      if (!mounted) return;
      pendingFocusDay.value = start;
      selectedTab.value = 1;
      navigator.popUntil((r) => r.isFirst);
      messenger.showSnackBar(const SnackBar(content: Text('모임이 생성됐어요')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(const SnackBar(content: Text('모임 생성에 실패했어요')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _date == null
        ? '날짜 선택'
        : DateFormat('y년 M월 d일 (E)', 'ko_KR').format(_date!);
    final timeLabel = _time == null ? '시간 선택' : _time!.format(context);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('모임 만들기'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('카테고리'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in CategoryCatalog.mainShortcuts)
                _chip(c.label, _category == c && _customCategory == null,
                    () => setState(() {
                          _category = c;
                          _customCategory = null;
                        })),
              if (_customCategory != null)
                _chip(_customCategory!, true,
                    () => setState(() {
                          _customCategory = null;
                          _category = null;
                        })),
              _browserChip(),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('제목'),
          TextField(
            key: const Key('title'),
            controller: _title,
            decoration: _inputDeco('어떤 모임인가요?'),
          ),
          const SizedBox(height: 20),
          _sectionTitle('일시'),
          Row(
            children: [
              Expanded(
                child: _pickerField(const Key('date'), Icons.calendar_today_rounded,
                    dateLabel, _date != null, _pickDate),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _pickerField(const Key('time'), Icons.schedule_rounded,
                    timeLabel, _time != null, _pickTime),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('장소'),
          SwitchListTile(
            key: const Key('online'),
            contentPadding: EdgeInsets.zero,
            title: const Text('온라인 모임', style: TextStyle(fontSize: 14)),
            value: _online,
            activeThumbColor: AppColors.textPrimary,
            onChanged: (v) => setState(() => _online = v),
          ),
          if (!_online) ...[
            const SizedBox(height: 4),
            _pickerField(
              const Key('location'),
              Icons.location_on_rounded,
              _locationId == null
                  ? '지역 선택'
                  : LocationCatalog.displayLabel(_locationId!),
              _locationId != null,
              _pickLocation,
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('place'),
              controller: _place,
              focusNode: _placeFocus,
              decoration: _inputDeco('구체적인 장소 (예: 강남역 2번 출구)'),
            ),
          ],
          const SizedBox(height: 20),
          _sectionTitle('인원 (방장 포함)'),
          Row(
            children: [
              _stepBtn(const Key('members-minus'), Icons.remove_rounded,
                  _members > _minMembers
                      ? () => _setMembers(_members - 1)
                      : null),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 72,
                  child: TextField(
                    key: const Key('members-input'),
                    controller: _membersCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: _inputDeco('').copyWith(
                      suffixText: '명',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                    ),
                    onChanged: _onMembersTyped,
                  ),
                ),
              ),
              _stepBtn(const Key('members-plus'), Icons.add_rounded,
                  _members < _maxMembers
                      ? () => _setMembers(_members + 1)
                      : null),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('비용'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in CostType.values)
                _chip(t.label, _costType == t,
                    () => setState(() => _costType = t)),
            ],
          ),
          if (_costType == CostType.paid) ...[
            const SizedBox(height: 10),
            TextField(
              key: const Key('amount'),
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: _inputDeco('1인당 금액 (원)'),
            ),
          ],
          if (_costType == CostType.custom) ...[
            const SizedBox(height: 10),
            TextField(
              key: const Key('cost-etc'),
              controller: _costEtc,
              decoration: _inputDeco('비용을 직접 입력해 주세요'),
            ),
          ],
          const SizedBox(height: 20),
          _sectionTitle('설명 (선택)'),
          TextField(
            key: const Key('description'),
            controller: _description,
            maxLines: 4,
            decoration: _inputDeco('모임을 소개해 주세요'),
          ),
          const SizedBox(height: 20),
          _sectionTitle('참가 방식'),
          for (final m in JoinMethod.values) ...[
            _joinCard(m),
            const SizedBox(height: 10),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('submit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: AppColors.bgPrimary,
                    disabledBackgroundColor: AppColors.bgTertiary,
                    disabledForegroundColor: AppColors.textTertiary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: (_valid && !_loading) ? _submit : null,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.bgPrimary,
                          ),
                        )
                      : const Text('모임 만들기',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
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
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(fontSize: 14, color: AppColors.textTertiary),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderTertiary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderTertiary),
        ),
        // 포커스 하이라이트는 코랄 대신 검정 톤.
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.textPrimary, width: 1.4),
        ),
      );

  Widget _chip(String label, bool selected, VoidCallback onTap) {
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

  Widget _browserChip() {
    return GestureDetector(
      key: const Key('category-browser-open'),
      onTap: _openCategoryBrowser,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderTertiary, width: 0.5),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grid_view_rounded,
                size: 14, color: AppColors.textSecondary),
            SizedBox(width: 4),
            Text('전체보기',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _pickerField(
      Key key, IconData icon, String label, bool filled, VoidCallback onTap) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderTertiary),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color: filled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBtn(Key key, IconData icon, VoidCallback? onTap) {
    return InkWell(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderTertiary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 18,
            color:
                onTap == null ? AppColors.textTertiary : AppColors.textPrimary),
      ),
    );
  }

  Widget _joinCard(JoinMethod m) {
    final selected = _joinMethod == m;
    return GestureDetector(
      onTap: () => setState(() => _joinMethod = m),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          border: Border.all(
            color: selected
                ? AppColors.textPrimary
                : AppColors.borderTertiary,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected
                  ? AppColors.textPrimary
                  : AppColors.textTertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(m.label,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      if (m == JoinMethod.approval) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.bgInfo,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('추천',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textInfo)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(m.summary,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
