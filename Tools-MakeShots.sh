#!/bin/bash
# ストア用のスクリーンショットを撮り直す。**日本語ぶんは store/、それ以外は英語で store/en/。**
#
#   ./Tools-MakeShots.sh            iPhone と Watch を両方
#   ./Tools-MakeShots.sh phone      iPhone だけ
#   ./Tools-MakeShots.sh watch      Watch だけ
#
# iPhone は 6.9 インチ（1320×2868）で撮る。**撮影用の入口は DEBUG 構成にしかない**
# （`OTT_SKIP_PERMISSION` / `OTT_STATE` / `OTT_SHOT` / `OTT_DESIGN` / `OTT_TIP_SAMPLE`）。
set -eo pipefail
cd "$(dirname "$0")"
ROOT="$PWD"
WHAT="${1:-all}"
PHONE=$(cat .sim-phone-max)
WATCH=$(cat .sim-watch)
PHONE_ID=com.zzzjjj080.OneTapTimer
# 既定の見た目（`FaceDesign.standard.text` と同じ）
STANDARD="Y1 C1 N1 S3 T1 F3 O1 P1 W1 I1 R1 V1 U2 J1"
WATCH_ID=com.zzzjjj080.OneTapTimer.watchkitapp

~/Claude/shared/tools/sim-wait.sh >/dev/null 2>&1 || true

shot() {   # shot <udid> <bundle> <言語> <出し先> <環境変数...>
  local dev=$1 bundle=$2 lang=$3 out=$4; shift 4
  xcrun simctl terminate "$dev" "$bundle" >/dev/null 2>&1 || true
  env "$@" SIMCTL_CHILD_OTT_SKIP_PERMISSION=1 \
    xcrun simctl launch "$dev" "$bundle" -AppleLanguages "($lang)" >/dev/null
  sleep 5
  xcrun simctl io "$dev" screenshot "$out" >/dev/null 2>&1
  echo "  撮った $out"
}

if [ "$WHAT" = all ] || [ "$WHAT" = phone ]; then
  echo "→ iPhone（$PHONE）"
  xcrun simctl boot "$PHONE" 2>/dev/null || true
  (cd OneTapTimer && xcodebuild -project OneTapTimer.xcodeproj -scheme OneTapTimer \
     -configuration Debug -destination "id=$PHONE" -derivedDataPath /tmp/ott-shots build 2>&1 \
     | grep -E "error:|BUILD SUCCEEDED")
  xcrun simctl install "$PHONE" /tmp/ott-shots/Build/Products/Debug-iphonesimulator/OneTapTimer.app
  for pair in "ja:store" "en:store/en"; do
    lang=${pair%%:*}; dir=$ROOT/${pair##*:}
    shot "$PHONE" "$PHONE_ID" "$lang" "$dir/phone-dial.png"
    shot "$PHONE" "$PHONE_ID" "$lang" "$dir/phone-face.png" SIMCTL_CHILD_OTT_SHOT=face
    # 見た目を変えられることが伝わる2枚（**最後に撮る。** 次の撮影の前に既定へ戻す）
    shot "$PHONE" "$PHONE_ID" "$lang" "$dir/phone-looks.png" \
      SIMCTL_CHILD_OTT_DESIGN="Y2 C5 N2 S4 T1 F3 O1 P1 W2 I2 R3 V3 U3 J1"
    shot "$PHONE" "$PHONE_ID" "$lang" "$dir/phone-looks2.png" \
      SIMCTL_CHILD_OTT_DESIGN="Y3 C8 N3 S2 T4 F2 O3 P3 W3 I3 R4 V2 U1 J3"
  done
  # 見た目を既定に戻しておく（次に撮るときに前の色が残らない）
  xcrun simctl terminate "$PHONE" "$PHONE_ID" >/dev/null 2>&1 || true
  env SIMCTL_CHILD_OTT_DESIGN="$STANDARD" SIMCTL_CHILD_OTT_SKIP_PERMISSION=1 \
    xcrun simctl launch "$PHONE" "$PHONE_ID" >/dev/null
  sleep 2; xcrun simctl terminate "$PHONE" "$PHONE_ID" >/dev/null 2>&1 || true
  xcrun simctl shutdown "$PHONE"
fi

if [ "$WHAT" = all ] || [ "$WHAT" = watch ]; then
  echo "→ Apple Watch（$WATCH）"
  xcrun simctl boot "$WATCH" 2>/dev/null || true
  (cd OneTapTimer && xcodebuild -project OneTapTimer.xcodeproj -scheme "OneTapTimer Watch App" \
     -configuration Debug -destination "id=$WATCH" -derivedDataPath /tmp/ott-shots-w build 2>&1 \
     | grep -E "error:|BUILD SUCCEEDED")
  xcrun simctl install "$WATCH" "/tmp/ott-shots-w/Build/Products/Debug-watchsimulator/OneTapTimer Watch App.app"
  for pair in "ja:store" "en:store/en"; do
    lang=${pair%%:*}; dir=$ROOT/${pair##*:}
    shot "$WATCH" "$WATCH_ID" "$lang" "$dir/watch-running.png" SIMCTL_CHILD_OTT_STATE=running:67
    shot "$WATCH" "$WATCH_ID" "$lang" "$dir/watch-paused.png" SIMCTL_CHILD_OTT_STATE=paused:45
    shot "$WATCH" "$WATCH_ID" "$lang" "$dir/watch-done.png" SIMCTL_CHILD_OTT_STATE=done
    shot "$WATCH" "$WATCH_ID" "$lang" "$dir/watch-settings.png" SIMCTL_CHILD_OTT_STATE=settings
  done
  xcrun simctl terminate "$WATCH" "$WATCH_ID" >/dev/null 2>&1 || true
  xcrun simctl shutdown "$WATCH"
fi

echo "✅ 撮り終えた（使い終わったシミュレータは閉じた）"
