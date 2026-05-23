import 'package:flutter/material.dart';
import '../../data/meeting_repository.dart';
import '../../models/meeting.dart';
import '../../theme/app_colors.dart';
import 'chat_preview.dart';
import 'chat_room_cell.dart';

/// 채팅 메인 화면. 전체/안읽음 두 탭으로 나뉘고,
/// 각 탭은 다가오는·진행중·종료된 모임 섹션을 차례로 보여준다.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.repository, this.now});

  final MeetingRepository repository;

  /// 테스트에서 단계 판정 기준 시각을 주입할 수 있게 한다.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.bgPrimary,
          elevation: 0,
          title: const Text('채팅',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          bottom: const TabBar(
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textTertiary,
            indicatorColor: AppColors.textPrimary,
            labelStyle:
                TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            tabs: [Tab(text: '전체'), Tab(text: '안읽음')],
          ),
        ),
        body: TabBarView(
          children: [
            _ChatList(repository: repository, now: now, onlyUnread: false),
            _ChatList(repository: repository, now: now, onlyUnread: true),
          ],
        ),
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  const _ChatList({
    required this.repository,
    required this.now,
    required this.onlyUnread,
  });

  final MeetingRepository repository;
  final DateTime? now;
  final bool onlyUnread;

  @override
  Widget build(BuildContext context) {
    final n = now ?? DateTime.now();

    final upcoming = <Meeting>[];
    final ongoing = <Meeting>[];
    final ended = <Meeting>[];
    for (final m in repository.allMeetings) {
      if (!chatStillAlive(m, n)) continue; // 51시간 지난 채팅방은 사라짐
      switch (meetingPhase(m, n)) {
        case MeetingPhase.upcoming:
          upcoming.add(m);
        case MeetingPhase.ongoing:
          ongoing.add(m);
        case MeetingPhase.ended:
          ended.add(m);
      }
    }
    upcoming.sort((a, b) => a.startTime.compareTo(b.startTime));
    ongoing.sort((a, b) => a.startTime.compareTo(b.startTime));
    ended.sort((a, b) => b.startTime.compareTo(a.startTime));

    List<Meeting> applyFilter(List<Meeting> list) {
      if (!onlyUnread) return list;
      return list
          .where((m) => ChatPreview.forMeeting(m).unreadCount > 0)
          .toList();
    }

    final sections = <_Section>[
      _Section('다가오는 모임', applyFilter(upcoming),
          (m) => upcomingLabel(m, n)),
      _Section('진행중인 모임', applyFilter(ongoing), (m) => ongoingLabel(m)),
      _Section('종료된 모임', applyFilter(ended), (m) => endedLabel(m, n)),
    ].where((s) => s.meetings.isNotEmpty).toList();

    if (sections.isEmpty) {
      return Center(
        child: Text(
          onlyUnread ? '읽지 않은 채팅이 없어요' : '아직 채팅이 없어요',
          style: const TextStyle(
              fontSize: 14, color: AppColors.textTertiary),
        ),
      );
    }

    return ListView(
      children: [
        for (final s in sections) ...[
          _SectionHeader(s.title),
          for (final m in s.meetings)
            ChatRoomCell(meeting: m, timeLabel: s.timeLabel(m)),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

class _Section {
  _Section(this.title, this.meetings, this.timeLabel);
  final String title;
  final List<Meeting> meetings;
  final String Function(Meeting) timeLabel;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary)),
    );
  }
}
