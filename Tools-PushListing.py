#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""`store/listing.json` の掲載文を App Store Connect に流し込む。

    ./Tools-PushListing.py <appStoreVersion の id>            文章だけ
    ./Tools-PushListing.py <appStoreVersion の id> --shots    画像も入れ直す
    ./Tools-PushListing.py <appStoreVersion の id> --primary  元の言語を en-US にする（公開後にだけ通る）

- 名前・副題・プライバシーURL は `appInfoLocalizations`（版ではなくアプリ側）
- 説明・キーワード・新機能・サポートURL は `appStoreVersionLocalizations`
- 画像は日本語だけ `store/*.png`、それ以外は英語の `store/en/*.png`
  （**審査に出す言語には画像が要る。** 無い言語があると提出で止まる）

文字数の上限（名前30・副題30・キーワード100）はここで確かめる。超えていたら流さずに止める。
"""
from __future__ import annotations
import json
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).parent
ASC = str(ROOT / "Tools-ASC.py")
APP_ID = "6811255797"
SHOTS = {"APP_WATCH_SERIES_10": ("watch", 4), "APP_IPHONE_67": ("phone", 4)}
ORDER = ["running", "paused", "done", "settings"]


def api(method: str, path: str, body: dict | None = None) -> dict:
    cmd = [ASC, method, path] + ([json.dumps(body, ensure_ascii=False)] if body else [])
    out = subprocess.run(cmd, capture_output=True, text=True).stdout
    head, _, rest = out.partition("\n")
    if not head.startswith("HTTP 2"):
        print(f"  ! {method} {path.split('?')[0]} → {head}\n{rest[:400]}")
        return {}
    return json.loads(rest) if rest.strip() else {}


def main() -> int:
    version_id = sys.argv[1]
    with_shots = "--shots" in sys.argv
    L = json.load(open(ROOT / "store/listing.json", encoding="utf-8"))
    text, urls = L["text"], L["urls"]

    # 上限を先に確かめる（1つでも超えていたら何も流さない）
    bad = []
    for lang, t in text.items():
        for key, limit in (("name", 30), ("subtitle", 30), ("keywords", 100)):
            if len(t[key]) > limit:
                bad.append(f"{lang} の {key} が {len(t[key])} 文字（上限 {limit}）")
    if bad:
        print("\n".join(bad))
        return 1

    # 名前・副題は「編集中」の枠に入れる。公開中の枠に入れようとすると 409 になる
    infos = api("get", f"/v1/apps/{APP_ID}/appInfos")["data"]
    editable = [i for i in infos if i["attributes"].get("appStoreState") != "READY_FOR_SALE"]
    app_info = (editable or infos)[0]["id"]
    have_info = {l["attributes"]["locale"]: l["id"]
                 for l in api("get", f"/v1/appInfos/{app_info}/appInfoLocalizations")["data"]}
    have_ver = {l["attributes"]["locale"]: l["id"]
                for l in api("get", f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations")["data"]}

    if "--primary" in sys.argv:
        print(api("patch", f"/v1/apps/{APP_ID}", {"data": {"type": "apps", "id": APP_ID,
              "attributes": {"primaryLocale": "en-US"}}}) and "元の言語を en-US にした")
        return 0

    for locale, lang in L["locales"].items():
        t = text[lang]
        u = urls.get(locale, urls["_default"])
        print(f"== {locale}（{lang}）")

        info_attrs = {"name": t["name"], "subtitle": t["subtitle"], "privacyPolicyUrl": u["privacy"]}
        if locale in have_info:
            api("patch", f"/v1/appInfoLocalizations/{have_info[locale]}",
                {"data": {"type": "appInfoLocalizations", "id": have_info[locale], "attributes": info_attrs}})
        else:
            r = api("post", "/v1/appInfoLocalizations",
                    {"data": {"type": "appInfoLocalizations", "attributes": {"locale": locale, **info_attrs},
                              "relationships": {"appInfo": {"data": {"type": "appInfos", "id": app_info}}}}})
            have_info[locale] = r.get("data", {}).get("id", "")

        ver_attrs = {"description": t["description"], "keywords": t["keywords"],
                     "whatsNew": t["whatsNew"], "supportUrl": u["support"]}
        if locale in have_ver:
            api("patch", f"/v1/appStoreVersionLocalizations/{have_ver[locale]}",
                {"data": {"type": "appStoreVersionLocalizations", "id": have_ver[locale], "attributes": ver_attrs}})
        else:
            r = api("post", "/v1/appStoreVersionLocalizations",
                    {"data": {"type": "appStoreVersionLocalizations", "attributes": {"locale": locale, **ver_attrs},
                              "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}}}})
            have_ver[locale] = r.get("data", {}).get("id", "")

        if with_shots and have_ver.get(locale):
            folder = ROOT / "store" if locale == "ja" else ROOT / "store/en"
            # 一時フォルダは実行ごとに分ける（同じ道具を2つ走らせると画像を取り合って落ちる）
            tmp = Path(tempfile.mkdtemp(prefix="ott-shots-"))
            for display, (kind, _) in SHOTS.items():
                tmp.mkdir(exist_ok=True)
                for i, state in enumerate(ORDER, start=1):
                    (tmp / f"{i}.png").write_bytes((folder / f"{kind}-{state}.png").read_bytes())
                subprocess.run([str(ROOT / "Tools-UploadScreenshots.py"), have_ver[locale], display, str(tmp)])
                for f in tmp.iterdir():
                    f.unlink()
            tmp.rmdir()
            time.sleep(1)
    print("おわり")
    return 0


if __name__ == "__main__":
    sys.exit(main())
