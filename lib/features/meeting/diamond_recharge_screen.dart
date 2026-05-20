import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';

class _Package {
  const _Package(this.diamonds, this.bonus, this.won, this.popular);
  final int diamonds;
  final String? bonus;
  final int won;
  final bool popular;
}

const _packages = <_Package>[
  _Package(1000, null, 1000, false),
  _Package(3300, '보너스 +300 (10%)', 3000, true),
  _Package(5750, '보너스 +750 (15%)', 5000, false),
  _Package(12000, '보너스 +2,000 (20%)', 10000, false),
];

/// 다이아 충전 화면. 실제 결제·광고는 범위 밖(no-op).
class DiamondRechargeScreen extends StatefulWidget {
  const DiamondRechargeScreen({super.key, required this.currentDiamonds});

  final int currentDiamonds;

  @override
  State<DiamondRechargeScreen> createState() => _DiamondRechargeScreenState();
}

class _DiamondRechargeScreenState extends State<DiamondRechargeScreen> {
  final NumberFormat _fmt = NumberFormat('#,###');
  late int _selected = _packages.indexWhere((p) => p.popular);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('다이아 충전'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _balanceCard(),
          const SizedBox(height: 24),
          const Text('충전 패키지',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          for (var i = 0; i < _packages.length; i++) _packageTile(i),
          const SizedBox(height: 24),
          _adCard(),
          const SizedBox(height: 24),
          _usageCard(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: AppColors.bgPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {},
              child: Text('₩${_fmt.format(_packages[_selected].won)} 결제하기',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _balanceCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgInfo,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text('현재 보유',
                style: TextStyle(fontSize: 12, color: AppColors.textInfo)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.diamond, size: 28, color: AppColors.textInfo),
                const SizedBox(width: 8),
                Text(_fmt.format(widget.currentDiamonds),
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textInfo)),
              ],
            ),
          ],
        ),
      );

  Widget _packageTile(int i) {
    final p = _packages[i];
    final selected = i == _selected;
    return GestureDetector(
      onTap: () => setState(() => _selected = i),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.borderInfo : AppColors.borderTertiary,
            width: selected ? 2 : 0.5,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                const Icon(Icons.diamond, size: 24, color: AppColors.textInfo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_fmt.format(p.diamonds)} 다이아',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                      if (p.bonus != null) ...[
                        const SizedBox(height: 2),
                        Text(p.bonus!,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSuccess)),
                      ],
                    ],
                  ),
                ),
                Text('₩${_fmt.format(p.won)}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
            if (p.popular)
              Positioned(
                top: -19,
                left: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bgInfo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('인기',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textInfo)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _adCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgWarning,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_circle_outline,
                size: 22, color: AppColors.textWarning),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('광고 보고 무료 충전',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textWarning)),
                  SizedBox(height: 2),
                  Text('15초 광고 시청 시 50 다이아',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.textWarning, width: 0.5),
              ),
              child: const Text('받기',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textWarning)),
            ),
          ],
        ),
      );

  Widget _usageCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('다이아는 어디에 쓰나요?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            _usageRow(Icons.add, '모임 만들기', '300 다이아'),
            const SizedBox(height: 8),
            _usageRow(Icons.chat_bubble_outline, '채팅방 참가', '50 다이아'),
          ],
        ),
      );

  Widget _usageRow(IconData icon, String label, String cost) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          Text(cost,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      );
}
