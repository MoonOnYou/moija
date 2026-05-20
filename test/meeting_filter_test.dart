import 'package:flutter_test/flutter_test.dart';
import 'package:moija/models/meeting.dart';
import 'package:moija/models/meeting_category.dart';
import 'package:moija/models/meeting_filter.dart';
import 'package:moija/models/time_band.dart';

Meeting _m({
  MeetingCategory category = MeetingCategory.bowling,
  String locationId = 'seoul-line2',
  int hour = 20,
}) =>
    Meeting(
      id: 'x',
      title: 't',
      category: category,
      startTime: DateTime(2026, 5, 16, hour),
      location: 'loc',
      region: 'r',
      locationId: locationId,
      currentMembers: 1,
      maxMembers: 4,
    );

void main() {
  test('empty filter matches everything', () {
    const f = MeetingFilter.empty();
    expect(f.isEmpty, isTrue);
    expect(f.matches(_m()), isTrue);
  });

  test('category filter', () {
    const f = MeetingFilter(categories: {MeetingCategory.bowling});
    expect(f.matches(_m(category: MeetingCategory.bowling)), isTrue);
    expect(f.matches(_m(category: MeetingCategory.cafe)), isFalse);
  });

  test('location filter', () {
    const f = MeetingFilter(locationIds: {'seoul-line2'});
    expect(f.matches(_m(locationId: 'seoul-line2')), isTrue);
    expect(f.matches(_m(locationId: 'seoul-line3')), isFalse);
  });

  test('time band filter', () {
    const f = MeetingFilter(timeBands: {TimeBand.evening});
    expect(f.matches(_m(hour: 19)), isTrue);
    expect(f.matches(_m(hour: 9)), isFalse);
  });

  test('combined filter requires all sections', () {
    const f = MeetingFilter(
      categories: {MeetingCategory.bowling},
      timeBands: {TimeBand.evening},
    );
    expect(f.matches(_m(category: MeetingCategory.bowling, hour: 19)), isTrue);
    expect(f.matches(_m(category: MeetingCategory.bowling, hour: 9)), isFalse);
  });

  test('activeCount sums selections', () {
    const f = MeetingFilter(
      categories: {MeetingCategory.bowling, MeetingCategory.cafe},
      timeBands: {TimeBand.evening},
    );
    expect(f.activeCount, 3);
  });

  test('toMap/fromMap round-trip', () {
    const f = MeetingFilter(
      categories: {MeetingCategory.bowling, MeetingCategory.cafe},
      locationIds: {'seoul-line2'},
      timeBands: {TimeBand.evening},
      customCategories: {'플로깅'},
    );
    final restored = MeetingFilter.fromMap(f.toMap());
    expect(restored.categories, f.categories);
    expect(restored.locationIds, f.locationIds);
    expect(restored.timeBands, f.timeBands);
    expect(restored.customCategories, f.customCategories);
  });

  test('fromMap ignores unknown enum names', () {
    final f = MeetingFilter.fromMap({
      'categories': ['bowling', 'unknownCat'],
      'timeBands': ['evening', 'nope'],
    });
    expect(f.categories, {MeetingCategory.bowling});
    expect(f.timeBands, {TimeBand.evening});
    expect(f.locationIds, isEmpty);
  });
}
