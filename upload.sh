#!/bin/bash
# アーカイブを作って App Store Connect へ上げる。
#
# iOS アプリ（Watch アプリ同梱）としてアーカイブする。`generic/platform=iOS` にすると
# App Store の配布方式が使える（watchOS 単体では出せない。引き継ぎ書 4-91）。
#
# 前提:
#   - App Store Connect にアプリ記録があること（本人が作る。API に CREATE が無い）
#   - 提出用プロファイル3枚（./Tools-MakeProfile.py dist）
#   - 配布用の証明書は専用キーチェーン interval-dist に入っている
set -eo pipefail
cd "$(dirname "$0")/OneTapTimer"

security unlock-keychain -p intervaltimer ~/Library/Keychains/interval-dist.keychain-db 2>/dev/null || true

echo "→ アーカイブ"
DIR=~/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)
mkdir -p "$DIR"
rm -rf "$DIR/OneTapTimer.xcarchive"
xcodebuild -project OneTapTimer.xcodeproj -scheme OneTapTimer -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$DIR/OneTapTimer.xcarchive" archive 2>&1 | grep -E "error:|ARCHIVE SUCCEEDED|ARCHIVE FAILED"

A="$DIR/OneTapTimer.xcarchive/Products/Applications/OneTapTimer.app"
echo "→ 上げる前の点検"
echo "   版 $(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$A/Info.plist") ($(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$A/Info.plist"))"
printf "   Watch: "; ls "$A/Watch"
printf "   拡張: "; ls "$A/Watch/OneTapTimer Watch App.app/PlugIns"
printf "   App Group: "; codesign -d --entitlements :- "$A/Watch/OneTapTimer Watch App.app" 2>/dev/null | grep -c "group.com.zzzjjj080.OneTapTimer"
printf "   確認用の入口（0 であること）: "; strings "$A/Watch/OneTapTimer Watch App.app/OneTapTimer Watch App" | grep -cE "OTT_STATE|OTT_SKIP_PERMISSION" || true

if [ "${1:-}" = "--archive-only" ]; then echo "✅ アーカイブまで: $DIR/OneTapTimer.xcarchive"; exit 0; fi

echo "→ 書き出してアップロード（App Store Connect の API キー）"
xcodebuild -exportArchive -archivePath "$DIR/OneTapTimer.xcarchive" \
  -exportOptionsPlist ExportOptions.plist -exportPath "$DIR/OneTapTimer-export" \
  -authenticationKeyPath ~/.appstoreconnect/private_keys/AuthKey_CH8R5RJGXQ.p8 \
  -authenticationKeyID CH8R5RJGXQ -authenticationKeyIssuerID cfeb84ca-47e6-45b2-8c5f-192212240b6c \
  2>&1 | grep -E "error:|EXPORT SUCCEEDED|EXPORT FAILED|Upload"
echo "✅ 上げた。App Store Connect で処理が終わるのを待つ（10分ほど）"
