import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meeting_filter.dart';

/// 필터를 기기 저장소에 영구 보관한다.
class FilterStorage {
  static const _key = 'meeting_filter';

  Future<void> save(MeetingFilter filter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(filter.toMap()));
  }

  Future<MeetingFilter> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const MeetingFilter.empty();
    return MeetingFilter.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }
}
