import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/location_catalog.dart';
import '../../data/meeting_repository.dart';
import '../../data/wallet.dart';
import '../../models/join_method.dart';
import '../../models/meeting.dart';
import '../../models/meeting_category.dart';
import '../../models/meeting_cost.dart';
import '../../theme/app_colors.dart';
import '../filter/location_picker_screen.dart';
import 'diamond_recharge_screen.dart';

const int _createCost = 300;
final DateTime _today = DateTime(2026, 5, 16);

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
  final _title = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  bool _online = false;
  String? _locationId;
  final _place = TextEditingController();
  int _members = 4;
  CostType? _costType;
  final _amount = TextEditingController();
  final _description = TextEditingController();
  JoinMethod _joinMethod = JoinMethod.approval;

  @override
  void initState() {
    super.initState();
    _title.addListener(_refresh);
    _amount.addListener(_refresh);
  }

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  bool get _valid {
    if (_category == null) return false;
    if (_title.text.trim().isEmpty) return false;
    if (_date == null || _time == null) return false;
    if (!_online && _locationId == null) return false;
    if (_members < 2) return false;
    if (_costType == null) return false;
    if (_costType == CostType.paid &&
        (int.tryParse(_amount.text.trim()) ?? 0) <= 0) {
      return false;
    }
    return true;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? _today,
      firstDate: _today,
      lastDate: DateTime(2027, 12, 31),
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

  void _submit() {
    final messenger = ScaffoldMessenger.of(context);
    if (widget.currentDiamonds < _createCost) {
      messenger.showSnackBar(const SnackBar(content: Text('다이아가 부족해요')));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DiamondRechargeScreen(currentDiamonds: widget.currentDiamonds),
        ),
      );
      return;
    }
    final start = DateTime(
        _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    final node = _online ? null : LocationCatalog.nodeById(_locationId!);
    final placeText = _place.text.trim();
    final region = _online
        ? '온라인'
        : (placeText.isNotEmpty ? placeText : (node?.label ?? ''));
    final meeting = Meeting(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      title: _title.text.trim(),
      category: _category!,
      startTime: start,
      location: _online
          ? (placeText.isEmpty ? '온라인' : placeText)
          : (placeText.isEmpty ? (node?.label ?? '') : placeText),
      region: region,
      locationId: _online ? 'online' : _locationId!,
      currentMembers: 1,
      maxMembers: _members,
      description: _description.text.trim(),
      nearestStation: _online ? '온라인' : (node?.label ?? ''),
      cost: _costType == CostType.paid
          ? MeetingCost(CostType.paid,
              amountWon: int.tryParse(_amount.text.trim()))
          : MeetingCost(_costType!),
      joinMethod: _joinMethod,
    );
    widget.repository.add(meeting);
    messenger.showSnackBar(const SnackBar(content: Text('모임이 생성됐어요')));
    Navigator.pop(context, meeting);
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
                _chip(c.label, _category == c,
                    () => setState(() => _category = c)),
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
                  : (LocationCatalog.nodeById(_locationId!)?.label ??
                      '지역 선택'),
              _locationId != null,
              _pickLocation,
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('place'),
              controller: _place,
              decoration: _inputDeco('구체적인 장소 (선택)'),
            ),
          ],
          const SizedBox(height: 20),
          _sectionTitle('인원 (방장 포함)'),
          Row(
            children: [
              _stepBtn(const Key('members-minus'), Icons.remove,
                  _members > 2 ? () => setState(() => _members--) : null),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$_members명',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              _stepBtn(const Key('members-plus'), Icons.add,
                  () => setState(() => _members++)),
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
              const Text('방이 생성되면 다이아 300개가 차감돼요',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              const SizedBox(height: 8),
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
                  const SizedBox(height: 6),
                  for (final b in m.bullets)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('· $b',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textTertiary)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
