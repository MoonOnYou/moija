import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/meeting.dart';

const _baseUrl = 'http://localhost:8000';

Future<void> createMeeting(Meeting m, {@visibleForTesting http.Client? client}) async {
  final c = client ?? http.Client();
  try {
    final body = <String, dynamic>{
      'title': m.title,
      'category': m.category.name,
      'custom_category': m.customCategory,
      'start_time': m.startTime.toIso8601String(),
      'location': m.location,
      'region': m.region,
      'location_id': m.locationId,
      'max_members': m.maxMembers,
      'description': m.description,
      'nearest_station': m.nearestStation,
      'join_method': m.joinMethod.name,
      'cost_type': m.cost.type.name,
      if (m.cost.amountWon != null) 'cost_amount_won': m.cost.amountWon,
      'cost_custom_text': m.cost.customText ?? '',
    };
    final response = await c.post(
      Uri.parse('$_baseUrl/api/meetings/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('서버 오류: ${response.statusCode}');
    }
  } finally {
    if (client == null) c.close();
  }
}
