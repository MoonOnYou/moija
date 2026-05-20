import 'meeting_category.dart';

class Meeting {
  const Meeting({
    required this.id,
    required this.title,
    required this.category,
    required this.startTime,
    required this.location,
    required this.currentMembers,
    required this.maxMembers,
  });

  final String id;
  final String title;
  final MeetingCategory category;
  final DateTime startTime;
  final String location;
  final int currentMembers;
  final int maxMembers;

  int get spotsLeft => maxMembers - currentMembers;
}
