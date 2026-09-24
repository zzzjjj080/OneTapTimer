#!/bin/bash
# iPhone 実機へ入れる。同じ Wi-Fi にいてロック解除されていれば USB は要らない。
set -eo pipefail
cd "$(dirname "$0")"
ROOT="$PWD"


# Wi-Fi 越しだと `connected` ではなく `available (paired)` で出る。どちらでも入る（引き継ぎ書 4-151）
find_phone() {
  xcrun devicectl list devices 2>/dev/null | grep '(iPhone' \
    | grep -E ' connected | available \(paired\) ' | grep -v 'no DDI' | head -1 || true
}
LINE=$(find_phone)
if [ -z "$LINE" ]; then
  echo "→ iPhone を起こしにいきます（最大60秒）"
  ID=$(xcrun devicectl list devices 2>/dev/null | grep '(iPhone' | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | head -1 || true)
  [ -n "$ID" ] && xcrun devicectl device info details --device "$ID" --timeout 60 >/dev/null 2>&1 || true
  LINE=$(find_phone)
fi
if [ -z "$LINE" ]; then
  echo "❌ iPhone が見えません（同じ Wi-Fi に置いてロックを解除してください）"
  exit 1
fi
DEV=$(echo "$LINE" | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')
echo "→ $(echo "$LINE" | sed -E 's/.*connected +//') にインストールします"

# 実機に入る版の印。**手で増やさない。** 未コミットだと + が付く（引き継ぎ書 4-145）
STAMP="b$(git rev-list --count HEAD)$(git diff --quiet HEAD -- . || echo +) $(date '+%m/%d %H:%M')"
echo "→ 印: $STAMP"

cd "$ROOT/OneTapTimer"
xcodebuild -project OneTapTimer.xcodeproj -scheme OneTapTimer -configuration Debug \
  -destination "platform=iOS,id=$DEV" -destination-timeout 30 -derivedDataPath /tmp/ott-phone-device \
  OTT_BUILD_STAMP="$STAMP" -allowProvisioningUpdates build 2>&1 | grep -E "error:|BUILD SUCCEEDED" | tee /tmp/ott-build.log
grep -q "BUILD SUCCEEDED" /tmp/ott-build.log || { echo "❌ ビルドが通っていないので入れません"; exit 1; }

xcrun devicectl device install app --device "$DEV" \
  /tmp/ott-phone-device/Build/Products/Debug-iphoneos/OneTapTimer.app 2>&1 | grep -E "bundleID"
echo "   設定画面のいちばん下に「$STAMP」が出ていれば入れ替わっています"
echo "✅ 完了。iPhone に「ワンタップタイマー」が入ります（中の Watch アプリは Watch 側の設定から入れられます）"
