import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/location_catalog.dart';
import '../../data/meeting_repository.dart';
import '../../data/wallet.dart';
import '../../models/join_method.dart';
import '../../models/meeting.dart';
import '../../models/meeting_category.dart';
import '../../models/meeting_cost.dart';
import '../../shell/app_navigation.dart';
import '../../theme/app_colors.dart';
import '../common/notice_screen.dart';
import '../filter/location_picker_screen.dart';
import 'diamond_recharge_screen.dart';

const int _createCost = 300;

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({
    super.key,
    required this.repository,
    this.currentDiamonds = Wallet.myDiamonds,
  });

  final MeetingRepository repository;
  final int currentDiamonds;

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
  int _members = 4;
  final _membersCtrl = TextEditingController(text: '4');
  CostType? _costType;
  final _amount = TextEditingController();
  final _costEtc = TextEditingController();
  final _description = TextEditingController();
  JoinMethod _joinMethod = JoinMethod.approval;

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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: today,
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 19, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
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
    }
  }

  Future<void> _addCustomCategory() async {
    final controller = TextEditingController(text: _customCategory ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('직접 입력'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('추가'),
          ),
        ],
      ),
    );
    if (text != null && text.trim().isNotEmpty) {
      setState(() {
        _customCategory = text.trim();
        _category = MeetingCategory.etc;
      });
    }
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
    // 실제 생성 전에 안내 화면을 띄우고, 동의해야 만들어진다.
    final agreed = await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => Notices.createMeeting()),
    );
    if (agreed != true || !mounted) return;
    final start = DateTime(
        _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    // region·노선·역 모두 displayLabel로 일관 처리(예: "광주 전체", "2호선", "2호선 강남").
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
    widget.repository.add(meeting);
    // 채팅 탭으로 이동하지만, 홈 캘린더는 새 모임 날짜로 자동 이동시켜
    // 다시 홈으로 돌아왔을 때 만들어진 모임이 바로 보이도록 한다.
    pendingFocusDay.value = start;
    selectedTab.value = 1; // 채팅 탭(2번째)으로 이동
    navigator.popUntil((r) => r.isFirst);
    messenger.showSnackBar(const SnackBar(content: Text('모임이 생성됐어요')));
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
          icon: const Icon(Icons.close),
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
              for (final c in MeetingCategory.values)
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
              _dashedChip('+ 직접 입력하기', _addCustomCategory),
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
                child: _pickerField(const Key('date'), Icons.calendar_today,
                    dateLabel, _date != null, _pickDate),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _pickerField(const Key('time'), Icons.schedule,
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
            activeThumbColor: AppColors.textInfo,
            onChanged: (v) => setState(() => _online = v),
          ),
          if (!_online) ...[
            const SizedBox(height: 4),
            _pickerField(
              const Key('location'),
              Icons.location_on_outlined,
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
              decoration: _inputDeco('구체적인 장소 (예: 강남역 2번 출구)'),
            ),
          ],
          const SizedBox(height: 20),
          _sectionTitle('인원 (방장 포함)'),
          Row(
            children: [
              _stepBtn(const Key('members-minus'), Icons.remove,
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
              _stepBtn(const Key('members-plus'), Icons.add,
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
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.bgPrimary,
                    disabledBackgroundColor: AppColors.bgTertiary,
                    disabledForegroundColor: AppColors.textTertiary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _valid ? _submit : null,
                  child: const Text('모임 만들기',
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

  Widget _dashedChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textTertiary),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
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
            color: selected ? AppColors.textInfo : AppColors.borderTertiary,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected ? AppColors.textInfo : AppColors.textTertiary,
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
