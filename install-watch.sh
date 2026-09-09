#!/bin/bash
# 修正のたびに Apple Watch へ入れるためのスクリプト。
# Watch は腕に着けてロック解除。iPhone が Mac と同じ Wi-Fi にいれば USB は要らない（引き継ぎ書「Mac 上のセッションで」）。
#
# Debug は自動署名（Xcode にアカウントがある）。API でプロファイルを作ると App Group 付きでは 500 が返るため。
set -eo pipefail
cd "$(dirname "$0")"
ROOT="$PWD"


# 一覧を眺めるだけでは繋がらない。**こちらから話しかけるとトンネルが張られる**（4-85）。
find_watch() {
  xcrun devicectl list devices 2>/dev/null | grep -i 'Apple Watch' | grep ' connected ' | grep -v 'no DDI' | head -1 || true
}
LINE=$(find_watch)
if [ -z "$LINE" ]; then
  echo "→ Watch を起こしにいきます（最大60秒）"
  ID=$(xcrun devicectl list devices 2>/dev/null | grep -i 'Apple Watch' | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | head -1 || true)
  [ -n "$ID" ] && xcrun devicectl device info details --device "$ID" --timeout 60 >/dev/null 2>&1 || true
  LINE=$(find_watch)
fi
if [ -z "$LINE" ]; then
  echo "❌ Apple Watch が接続されていません。腕に着けてロックを解除し、iPhone を同じ Wi-Fi に置いてください。"
  xcrun devicectl list devices 2>/dev/null | grep -i 'watch' || echo "   （Watchが1台も見えていません）"
  exit 1
fi
DEV=$(echo "$LINE" | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')
echo "→ $(echo "$LINE" | sed -E 's/.*connected +//') にインストールします"

cd "$ROOT/OneTapTimer"
xcodebuild -project OneTapTimer.xcodeproj -scheme "OneTapTimer Watch App" -configuration Debug \
  -destination "platform=watchOS,id=$DEV" -destination-timeout 30 -derivedDataPath /tmp/ott-device \
  -allowProvisioningUpdates build 2>&1 | grep -E "error:|BUILD SUCCEEDED" | tee /tmp/ott-build.log
grep -q "BUILD SUCCEEDED" /tmp/ott-build.log || { echo "❌ ビルドが通っていないので入れません"; exit 1; }

# 初回はタイムアウトすることがある。失敗したら1回だけ再実行する
for i in 1 2; do
  if xcrun devicectl device install app --device "$DEV" \
      "/tmp/ott-device/Build/Products/Debug-watchos/OneTapTimer Watch App.app" 2>&1 | grep -E "bundleID"; then
    echo "✅ 完了。Watch のホーム画面に「ワンタップ」が出ます"; exit 0
  fi
  echo "→ もう一度"
done
exit 1
