#!/usr/bin/env bash
#
# 안드로이드 실기기/에뮬레이터에서 Mac의 로컬 서버(localhost:8000)에 붙여 앱을 실행한다.
# 기기의 localhost:8000 → Mac의 localhost:8000 으로 adb reverse 터널을 건 뒤 flutter run.
#
# 사용법:
#   ./scripts/dev-android.sh                 # 연결된 기기로 실행(여러 대면 flutter가 선택 프롬프트)
#   ./scripts/dev-android.sh -d emulator-5554   # 특정 기기로 실행
#   그 밖의 인자는 모두 flutter run 으로 전달된다.
#
set -euo pipefail

PORT=8000

# --- adb 위치 찾기 (PATH에 없을 수 있어 SDK 기본 경로도 탐색) ---
find_adb() {
  if command -v adb >/dev/null 2>&1; then command -v adb; return; fi
  for p in "$HOME/Library/Android/sdk/platform-tools/adb" \
           "${ANDROID_HOME:-}/platform-tools/adb" \
           "${ANDROID_SDK_ROOT:-}/platform-tools/adb"; do
    if [ -x "$p" ]; then echo "$p"; return; fi
  done
  echo ""
}
ADB="$(find_adb)"
if [ -z "$ADB" ]; then
  echo "❌ adb를 찾을 수 없습니다. Android SDK platform-tools 설치를 확인하세요." >&2
  exit 1
fi

# --- 연결된 기기 수집 (state=device 인 것만; macOS 기본 bash 3.2 호환) ---
DEVICES=()
while IFS= read -r serial; do
  [ -n "$serial" ] && DEVICES+=("$serial")
done < <("$ADB" devices | awk 'NR>1 && $2=="device" {print $1}')

if [ ${#DEVICES[@]} -eq 0 ]; then
  echo "❌ 연결된 안드로이드 기기가 없습니다. USB 연결 또는 에뮬레이터 실행 후 다시 시도하세요." >&2
  exit 1
fi

# --- 각 기기에 adb reverse 터널 설정 ---
for serial in "${DEVICES[@]}"; do
  "$ADB" -s "$serial" reverse tcp:$PORT tcp:$PORT >/dev/null
  echo "🔌 [$serial] localhost:$PORT → Mac:$PORT 터널 연결됨"
done

# --- 로컬 서버 응답 확인 (경고만, 중단하지 않음) ---
if ! curl -s -m 2 -o /dev/null "http://localhost:$PORT/" 2>/dev/null; then
  echo "⚠️  localhost:$PORT 서버가 응답하지 않습니다. moija-server를 먼저 실행하세요:"
  echo "     (cd ../moija-server && uv run manage.py runserver)"
fi

echo "🚀 flutter run $*"
exec flutter run "$@"
