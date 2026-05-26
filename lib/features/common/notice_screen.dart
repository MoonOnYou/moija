import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 안내 화면 항목 한 줄(아이콘 + 굵은 줄 + 선택 보조줄).
class NoticeItem {
  const NoticeItem(this.icon, this.color, this.lead, [this.sub]);

  final IconData icon;
  final Color color;
  final String lead;
  final String? sub;
}

/// 동작(모임 만들기/참가) 전에 띄우는 안내·동의 화면.
///
/// 동의하면 `Navigator.pop(context, true)`, 닫기/뒤로가기는 `false`(또는 null).
/// (docs/page/22, 23, 23b 안내 목업을 Flutter로 옮긴 것)
class NoticeScreen extends StatelessWidget {
  const NoticeScreen({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.badge,
    this.badgeColor,
    required this.items,
    this.showHostMessage = false,
    required this.buttonLabel,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;

  /// 제목 아래 작은 강조 부제(예: "선착순 모임 · 즉시 확정").
  final String? badge;
  final Color? badgeColor;

  final List<NoticeItem> items;

  /// 승인제 안내의 "방장에게 한마디(선택)" 입력칸 노출 여부.
  final bool showHostMessage;

  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Column(
        // 바깥 Column 기본값(center)이면 너비가 콘텐츠에 맞춰진 헤더 Padding이
        // 가운데로 정렬돼 왼쪽이 비어 보인다. start로 고정해 왼쪽 끝에 붙인다.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, size: 27, color: iconColor),
                ),
                const SizedBox(height: 14),
                Text(title,
                    style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        height: 1.3)),
                if (badge != null) ...[
                  const SizedBox(height: 6),
                  Text(badge!,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: badgeColor ?? AppColors.textInfo)),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              children: [
                for (final item in items) ...[
                  _itemRow(item),
                  const SizedBox(height: 17),
                ],
                if (showHostMessage) _hostMessage(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: AppColors.borderTertiary, width: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('notice-agree'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      foregroundColor: AppColors.bgPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(buttonLabel,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('커뮤니티 규칙 · 이용약관에 동의합니다',
                    style:
                        TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(NoticeItem item) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Icon(item.icon, size: 20, color: item.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.lead,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                if (item.sub != null) ...[
                  const SizedBox(height: 1),
                  Text(item.sub!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      );

  Widget _hostMessage() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('방장에게 한마디',
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Text('선택',
                  style: TextStyle(
                      fontSize: 10, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 7),
          TextField(
            key: const Key('host-message'),
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: '모임은 처음인데 잘 부탁해요!',
              hintStyle:
                  const TextStyle(fontSize: 13, color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.bgSecondary,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.borderTertiary, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.borderTertiary, width: 0.5),
              ),
            ),
          ),
        ],
      );
}

/// 화면별 안내 콘텐츠 정의(docs/page/22·23·23b).
class Notices {
  const Notices._();

  /// #22 모임 만들기 전 안내.
  static NoticeScreen createMeeting() => const NoticeScreen(
        icon: Icons.event_available_rounded,
        iconColor: AppColors.textInfo,
        iconBg: AppColors.bgInfo,
        title: '모임을 만들기 전에\n확인해주세요',
        items: [
          NoticeItem(Icons.diamond_rounded, AppColors.textInfo,
              '다이아 300개로 모임을 만들어요'),
          NoticeItem(Icons.schedule_rounded, AppColors.textSecondary,
              '모임 시작 후 48시간까지 채팅이 유지돼요', '정산을 마무리 해 주세요'),
          NoticeItem(Icons.fact_check_rounded, AppColors.textSecondary,
              '방장은 출석 체크와 정산 확인을 해주세요'),
          NoticeItem(Icons.warning_amber_rounded, AppColors.textDanger,
              '피치 못 할 경우 미리 방장을 넘겨주세요',
              '무단 불참·임의 취소는 이용이 제한될 수 있어요'),
        ],
        buttonLabel: '동의하고 모임 만들기',
      );

  /// #23 선착순 참가 전 안내.
  static NoticeScreen joinFirstCome() => const NoticeScreen(
        icon: Icons.bolt_rounded,
        iconColor: AppColors.textSuccess,
        iconBg: AppColors.bgSuccess,
        title: '바로 참가하기 전에\n확인해주세요',
        badge: '선착순 모임 · 즉시 확정',
        badgeColor: AppColors.textSuccess,
        items: [
          NoticeItem(Icons.diamond_rounded, AppColors.textInfo,
              '바로 참가하고 50 다이아를 사용해요', '즉시 채팅방에 입장헤요'),
          NoticeItem(Icons.star_border_rounded, AppColors.textWarning,
              '참여하면 멤버들이 내 매너점수를 매길 수 있어요'),
          NoticeItem(Icons.schedule_rounded, AppColors.textSecondary,
              '모임이 시작 후 48시간까지 채팅이 유지돼요', '정산을 마무리 해 주세요'),
          NoticeItem(Icons.warning_amber_rounded, AppColors.textDanger,
              '무단 이탈·노쇼·미정산은 제한을 받을 수 있어요',
              '매너점수 하락 및 앱 이용에 제한을 받아요'),
        ],
        buttonLabel: '동의하고 바로 참가하기 · 50 다이아',
      );

  /// #23b 승인제 참가 신청 전 안내.
  static NoticeScreen joinApproval() => const NoticeScreen(
        icon: Icons.how_to_reg_rounded,
        iconColor: AppColors.textInfo,
        iconBg: AppColors.bgInfo,
        title: '참가 신청하기 전에\n확인해주세요',
        badge: '승인제 모임 · 방장 수락 필요',
        badgeColor: AppColors.textInfo,
        showHostMessage: true,
        items: [
          NoticeItem(Icons.diamond_rounded, AppColors.textInfo,
              '방장이 수락하면 50 다이아를 사용해요', '신청은 무료 · 거절되면 차감 없어요'),
          NoticeItem(Icons.star_border_rounded, AppColors.textWarning,
              '참여하면 멤버들이 내 매너점수를 매길 수 있어요'),
          NoticeItem(Icons.schedule_rounded, AppColors.textSecondary,
              '모임이 시작 후 48시간까지 채팅이 유지돼요', '정산을 마무리 해 주세요'),
          NoticeItem(Icons.warning_amber_rounded, AppColors.textDanger,
              '무단 이탈·노쇼·미정산은 제한을 받을 수 있어요',
              '매너점수 하락 및 앱 이용에 제한을 받아요'),
        ],
        buttonLabel: '동의하고 참가 신청하기',
      );
}
