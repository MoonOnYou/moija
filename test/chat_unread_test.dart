import 'package:flutter_test/flutter_test.dart';
import 'package:moija/features/chat/chat_message.dart';

ChatMessage _user(String id, DateTime at, {bool mine = false}) => ChatMessage(
      id: id,
      type: ChatMessageType.user,
      text: 't',
      sentAt: at,
      sender: mine ? kMyNickname : '상대',
      mine: mine,
    );

ChatMessage _sys(String id, DateTime at) => ChatMessage(
      id: id,
      type: ChatMessageType.system,
      text: 's',
      sentAt: at,
    );

void main() {
  final base = DateTime(2026, 6, 1, 12);
  DateTime t(int i) => base.add(Duration(minutes: i));

  test('최신 메시지부터 cap, cap-1 … 으로 내려가고 오래된 건 0(미포함)', () {
    // 오래된→최신 순. 참가자 4명.
    final ordered = [
      _user('a', t(0), mine: true),
      _user('b', t(1), mine: true),
      _user('c', t(2), mine: true),
      _user('d', t(3), mine: true),
      _user('e', t(4), mine: true),
    ];
    final counts = unreadCountsFor(ordered, 4);

    // 내 메시지 cap=4. 최신(e)=4, d=3, c=2, b=1, a=0(미포함)
    expect(counts['e'], 4);
    expect(counts['d'], 3);
    expect(counts['c'], 2);
    expect(counts['b'], 1);
    expect(counts.containsKey('a'), isFalse);
  });

  test('상대 메시지 cap은 참가자 수 - 1', () {
    final ordered = [
      _user('x', t(0)), // 상대
      _user('y', t(1)), // 상대 (최신)
    ];
    final counts = unreadCountsFor(ordered, 4);
    // 상대 cap=3. 최신(y)=3, x=3-1=2
    expect(counts['y'], 3);
    expect(counts['x'], 2);
  });

  test('시스템 메시지는 순위에서 제외되고 숫자도 없다', () {
    final ordered = [
      _user('a', t(0), mine: true),
      _sys('sys', t(1)),
      _user('b', t(2), mine: true),
    ];
    final counts = unreadCountsFor(ordered, 4);
    // 사용자 메시지만 순위: 최신 b=4, a=3. 시스템은 키 없음.
    expect(counts['b'], 4);
    expect(counts['a'], 3);
    expect(counts.containsKey('sys'), isFalse);
  });

  test('참가자가 너무 적어 cap이 0 이하이면 표시하지 않는다', () {
    final ordered = [
      _user('a', t(0)), // 상대, cap = 1-1 = 0
      _user('b', t(1), mine: true), // 내 것, cap = 1
    ];
    final counts = unreadCountsFor(ordered, 1);
    expect(counts['b'], 1); // 내 메시지 최신, cap1 → 1
    expect(counts.containsKey('a'), isFalse); // 상대 cap0
  });
}
