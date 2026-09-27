#!/bin/bash
# 番号付きの見本表（design/catalog-1.png・-2.png）を作り直す。**選択肢を足す・消すたびに回す。**
#
# 描くのに要るファイルだけを Mac 向けにまとめてコンパイルする（シミュレータは使わない）。
# `bundle: .module` は SwiftPM の外では使えないので、その場で外す。
set -eo pipefail
cd "$(dirname "$0")"
ROOT="$PWD"
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT

for f in FaceDesign ThemeHex PaletteHex TimeText TimerEngine DurationRule Units; do
  cp "OneTapTimerCore/Sources/OneTapTimerCore/$f.swift" "$W/"
done
for f in Skin DrainFace; do
  sed -e '/^import OneTapTimerCore$/d' -e 's/, bundle: .module//g' \
      "OneTapTimerUI/Sources/OneTapTimerUI/$f.swift" > "$W/$f.swift"
done
cp Tools-MakeCatalog.swift "$W/main.swift"

swiftc -O -o "$W/catalog" "$W"/*.swift
mkdir -p "$ROOT/design"
"$W/catalog" "$ROOT/design/catalog-1.png" 1
"$W/catalog" "$ROOT/design/catalog-2.png" 2
echo "✅ design/catalog-1.png と -2.png を作り直した"
