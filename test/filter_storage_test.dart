import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moija/data/filter_storage.dart';
import 'package:moija/models/meeting_category.dart';
import 'package:moija/models/meeting_filter.dart';
import 'package:moija/models/time_band.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('load returns empty when nothing saved', () async {
    final f = await FilterStorage().load();
    expect(f.isEmpty, isTrue);
  });

  test('save then load restores the filter', () async {
    const filter = MeetingFilter(
      categories: {MeetingCategory.bowling},
      locationIds: {'seoul-line2'},
      timeBands: {TimeBand.evening},
      customCategories: {'플로깅'},
    );
    final storage = FilterStorage();
    await storage.save(filter);
    final restored = await storage.load();
    expect(restored.categories, {MeetingCategory.bowling});
    expect(restored.locationIds, {'seoul-line2'});
    expect(restored.timeBands, {TimeBand.evening});
    expect(restored.customCategories, {'플로깅'});
  });
}
