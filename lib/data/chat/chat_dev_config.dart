/// 채팅 실서버 연동을 위한 임시 개발 설정.
///
/// 로그인/인증과 "내 모임" API가 아직 없어 앱은 현재 사용자의 participant id를
/// 알 수 없다. 그래서 개발/데모 중에는 아래 세 값을 빌드 시 `--dart-define`으로
/// 주입해 특정 서버 모임에 실제로 붙는다. 세 값이 모두 채워졌을 때만 라이브 모드가
/// 켜지고, 아니면 기존 mock 채팅으로 동작한다(회귀 없음).
///
/// ```bash
/// flutter run \
///   --dart-define=CHAT_LIVE_MEETING_ID=88a3c874-1cf9-4ac9-b622-6efd763488d1 \
///   --dart-define=CHAT_LIVE_PARTICIPANT_ID=1711 \
///   --dart-define=CHAT_LIVE_NICKNAME=온유
/// ```
///
/// TODO(auth): 인증·"내 모임" API 연동 시 이 설정을 제거하고, 로그인 사용자의
/// participant id / 닉네임과 실제 참여 중인 모임 id로 교체한다.
class ChatDevConfig {
  const ChatDevConfig._();

  /// 라이브로 붙을 서버 모임 UUID. 빈 문자열이면 라이브 비활성.
  static const String meetingId =
      String.fromEnvironment('CHAT_LIVE_MEETING_ID', defaultValue: '');

  /// 현재 사용자의 서버 participant id. 0이면 라이브 비활성.
  static const int participantId =
      int.fromEnvironment('CHAT_LIVE_PARTICIPANT_ID', defaultValue: 0);

  /// 현재 사용자의 서버 닉네임. 서버가 메시지 sender를 닉네임 문자열로만 주므로,
  /// 내 메시지("mine") 판정에 쓴다.
  static const String nickname =
      String.fromEnvironment('CHAT_LIVE_NICKNAME', defaultValue: '');

  /// 세 값이 모두 채워지면 라이브 모드.
  static bool get isLive =>
      meetingId.isNotEmpty && participantId > 0 && nickname.isNotEmpty;
}
