#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""`translations.json` から、文字列カタログと単位の表を作り直す。

訳を直すのは `translations.json` だけ。ここを走らせると次が書き換わる:

    OneTapTimerUI/Sources/OneTapTimerUI/Resources/Localizable.xcstrings   画面の文言
    OneTapTimer/OneTapTimer/Localizable.xcstrings                          Watch アプリ
    OneTapTimer/OneTapTimerWidget/Localizable.xcstrings                    コンプリケーション
    OneTapTimer/OneTapTimer/InfoPlist.xcstrings                            Watch の表示名
    OneTapTimer/OneTapTimerPhone/InfoPlist.xcstrings                       iPhone の表示名
    OneTapTimerCore/Sources/OneTapTimerCore/Units.swift                    分・秒の短い単位

カタログのキーは日本語のまま。**原語は en**（開発地域も en。ずれると片方の言語が壊れる。
引き継ぎ書 4-157）なので、ja も含めて全言語を訳として明示する。

    ./Tools-GenTranslations.py          書き換える
    ./Tools-GenTranslations.py --check  差が出るかだけ見る（CI 用。書き換えない）
"""
from __future__ import annotations
import collections
import json
import sys
from pathlib import Path

ROOT = Path(__file__).parent
OD = collections.OrderedDict
CHECK = "--check" in sys.argv

T = json.load(open(ROOT / "translations.json", encoding="utf-8"))
LANGS: list[str] = T["languages"]
UNITS: dict[str, list[str]] = {k: v for k, v in T["_units"].items() if not k.startswith("_")}

# カタログごとに、入れるキー。値は「言語 → 文字列」を返す関数。
def plain(key: str):
    return lambda lang: T[key][lang]

def minute(lang: str) -> str: return UNITS[lang][0]
def second(lang: str) -> str: return UNITS[lang][1]

CATALOGS: dict[str, dict[str, object]] = {
    "OneTapTimerUI/Sources/OneTapTimerUI/Resources/Localizable.xcstrings": {
        "分": minute, "秒": second,
        "おわり": plain("おわり"), "一時停止中": plain("一時停止中"),
        "タップで始める": plain("タップで始める"), "時間を変える": plain("時間を変える"),
        "一時停止": plain("一時停止"), "再開": plain("再開"),
        "色": plain("色"), "完了": plain("完了"),
        # 設定のいちばん下のリンク（1.4 で投げ銭をここに替えた）
        "作者の他のアプリ": plain("作者の他のアプリ"),
        # 見た目を決める画面（iPhone）。選択肢そのものは番号と絵なので、訳が要るのは種類の名前だけ
        "文字盤": plain("文字盤"), "アプリの画面": plain("アプリの画面"),
        "中身": plain("中身"), "絵": plain("絵"), "輪": plain("輪"),
        "色の付け方": plain("色の付け方"), "大きさ": plain("大きさ"), "書体": plain("書体"),
        "減り方": plain("減り方"), "数字": plain("数字"),
        "文字の太さ": plain("文字の太さ"), "縁取り": plain("縁取り"), "置き場所": plain("置き場所"),
        "はじめに戻す": plain("はじめに戻す"),
    },
    "OneTapTimer/OneTapTimer/Localizable.xcstrings": {
        "キャンセル": plain("キャンセル"),
    },
    "OneTapTimer/OneTapTimerWidget/Localizable.xcstrings": {
        "ワンタップタイマー": plain("ワンタップタイマー"),
        "ワンタップ": plain("ワンタップ"),
        "押すと始まる": plain("押すと始まる"),
        "タップするとタイマーが始まります。": plain("タップするとタイマーが始まります。"),
        "秒": second,
        "のこり": plain("のこり"),
        # 「90秒 · 押すと始まる」の後ろ半分。数字のうしろに単位を続けて置く
        "秒 · 押すと始まる": lambda lang: f"{second(lang)} · {T['押すと始まる'][lang]}",
    },
    "OneTapTimer/OneTapTimer/InfoPlist.xcstrings": {
        "CFBundleDisplayName": plain("ワンタップ"),
    },
    "OneTapTimer/OneTapTimerPhone/InfoPlist.xcstrings": {
        "CFBundleDisplayName": plain("ワンタップタイマー"),
    },
}

UNITS_SWIFT = '''import Foundation

/// 分と秒の短い単位。**`Tools-GenTranslations.py` が作る。手で直さない**
/// （直すのは `translations.json`）。
///
/// 文字列カタログは数字と混ぜた形を拾えないので、ここだけ表にしている。
public enum Units {

    /// 言語コード → (分, 秒)。
    public static let byLanguage: [String: (minute: String, second: String)] = [
%s
    ]

    /// 端末の言語に合う単位。知らない言語は英語（`m` / `s`）。
    /// 中国語は簡体字と繁体字で同じなので、地域までは見ない。
    public static func of(_ locale: Locale) -> (minute: String, second: String) {
        let code = locale.language.languageCode?.identifier ?? "en"
        if code == "zh" { return byLanguage["zh-Hans"] ?? ("m", "s") }
        return byLanguage[code] ?? byLanguage["en"]!
    }
}
'''


def write(path: Path, text: str) -> bool:
    old = path.read_text(encoding="utf-8") if path.exists() else ""
    if old == text:
        return False
    if not CHECK:
        path.write_text(text, encoding="utf-8")
    print(("差がある: " if CHECK else "書いた: ") + str(path.relative_to(ROOT)))
    return True


changed = False

for rel, keys in CATALOGS.items():
    path = ROOT / rel
    doc = json.load(open(path, encoding="utf-8"), object_pairs_hook=OD)
    doc["sourceLanguage"] = "en"
    for key, value in keys.items():
        entry = doc["strings"].setdefault(key, OD())
        locs = entry.setdefault("localizations", OD())
        for lang in LANGS:
            locs[lang] = {"stringUnit": {"state": "translated", "value": value(lang)}}
        # 使わなくなった言語は落とす（訳が中途半端に残ると、その言語だけ古い文言が出る）
        for lang in [l for l in locs if l not in LANGS]:
            del locs[lang]
    # **使わなくなった文言も落とす。** 足すだけにしていたら、投げ銭をやめた後も
    # 「コーヒーを奢る」がカタログに残っていた（2026-09-30）
    for key in [k for k in doc["strings"] if k not in keys]:
        del doc["strings"][key]
    changed |= write(path, json.dumps(doc, ensure_ascii=False, indent=2) + "\n")

rows = ",\n".join(
    f'        "{lang}": ("{UNITS[lang][0]}", "{UNITS[lang][1]}")' for lang in LANGS
)
changed |= write(ROOT / "OneTapTimerCore/Sources/OneTapTimerCore/Units.swift", UNITS_SWIFT % rows)

if CHECK and changed:
    print("`./Tools-GenTranslations.py` を走らせ直してください")
    sys.exit(1)
print("言語:", " ".join(LANGS))
