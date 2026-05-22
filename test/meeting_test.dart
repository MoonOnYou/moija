import 'package:flutter_test/flutter_test.dart';
import 'package:moija/models/meeting.dart';
import 'package:moija/models/meeting_category.dart';
import 'package:moija/models/join_method.dart';

void main() {
  test('spotsLeft = max - current', () {
    final m = Meeting(
      id: '1',
      title: '방탈출 호러 테마 같이!',
      category: MeetingCategory.escapeRoom,
      startTime: DateTime(2026, 5, 19, 20, 0),
      location: '강남 비밀의방',
      region: '강남',
      locationId: 'seoul-line2',
      currentMembers: 2,
      maxMembers: 4,
    );
    expect(m.spotsLeft, 2);
    expect(m.locationId, 'seoul-line2');
  });

  test('joinMethod 기본값은 승인제', () {
    final m = Meeting(
      id: '1',
      title: 't',
      category: MeetingCategory.cafe,
      startTime: DateTime(2026, 5, 19, 20, 0),
      location: 'x',
      region: 'x',
      locationId: 'seoul-line2',
      currentMembers: 1,
      maxMembers: 4,
    );
    expect(m.joinMethod, JoinMethod.approval);
  });

  test('placeLabel은 인근역과 장소를 합쳐 보여준다', () {
    Meeting build({required String near, required String loc}) => Meeting(
          id: '1',
          title: 't',
          category: MeetingCategory.cafe,
          startTime: DateTime(2026, 5, 19, 20, 0),
          location: loc,
          region: 'x',
          locationId: 'seoul-line2',
          currentMembers: 1,
          maxMembers: 4,
          nearestStation: near,
        );
    expect(build(near: '강남 인근', loc: '강남 비밀의방').placeLabel, '강남 인근 · 강남 비밀의방');
    // 인근역이 없거나 장소와 같으면 장소만.
    expect(build(near: '', loc: '강남 비밀의방').placeLabel, '강남 비밀의방');
    expect(build(near: '온라인', loc: '온라인').placeLabel, '온라인');
  });
}
