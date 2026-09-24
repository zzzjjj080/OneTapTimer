#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""投げ銭（コーヒー1杯）の課金アイテムを App Store Connect に作る。

    ./Tools-MakeTip.py            作る／足りないところだけ足す
    ./Tools-MakeTip.py --status   いまの状態を見るだけ

引き継ぎ書 11-8 の順番どおり。**4つ揃うまで MISSING_METADATA のまま。**

1. 製品本体（消耗型）
2. 表示名と説明（言語ごと。関係のキーは inAppPurchase ではなく inAppPurchaseV2）
3. 価格（pricePoints から ¥200 の id を拾って価格表を作る）
4. 配信地域（**忘れると READY_TO_SUBMIT にならない**。アプリ本体と同じ地域）
5. 審査用スクリーンショット（1枚必須。作る → PUT で上げる → uploaded=true）

初回の消耗型は**アプリの版と一緒にしか審査へ出せない**（FIRST_CONSUMABLE_MUST_BE_SUBMITTED_ON_VERSION）。
"""
from __future__ import annotations
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).parent
ASC = str(ROOT / "Tools-ASC.py")
APP_ID = "6811255797"
SHOT = ROOT / "store/tip-review.png"
STATUS = "--status" in sys.argv


def api(method: str, path: str, body: dict | None = None) -> tuple[str, dict]:
    cmd = [ASC, method, path] + ([json.dumps(body, ensure_ascii=False)] if body else [])
    out = subprocess.run(cmd, capture_output=True, text=True).stdout
    head, _, rest = out.partition("\n")
    data = json.loads(rest) if rest.strip() else {}
    if not head.startswith("HTTP 2"):
        print(f"  ! {method} {path.split('?')[0]} → {head} {json.dumps(data, ensure_ascii=False)[:300]}")
    return head, data


def main() -> int:
    L = json.load(open(ROOT / "store/listing.json", encoding="utf-8"))
    tip = L["tip"]
    product_id = tip["productId"]

    _, found = api("get", f"/v1/apps/{APP_ID}/inAppPurchasesV2?limit=50")
    mine = [x for x in found.get("data", []) if x["attributes"]["productId"] == product_id]

    if mine:
        iap = mine[0]["id"]
        print(f"すでにある: {iap} 状態 {mine[0]['attributes'].get('state')}")
    elif STATUS:
        print("まだ無い")
        return 0
    else:
        _, made = api("post", "/v2/inAppPurchases", {"data": {
            "type": "inAppPurchases",
            "attributes": {"name": tip["referenceName"], "productId": product_id,
                           "inAppPurchaseType": "CONSUMABLE", "familySharable": False,
                           "reviewNote": tip["reviewNote"]},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}}}})
        iap = made["data"]["id"]
        print("作った:", iap)

    if STATUS:
        _, s = api("get", f"/v2/inAppPurchases/{iap}")
        print("状態:", s["data"]["attributes"].get("state"))
        # 1つしか無い関係に `limit` を付けると 400 になる（文言・価格の複数形だけ付けられる）
        for what, many in (("inAppPurchaseLocalizations", True), ("iapPriceSchedule", False),
                           ("inAppPurchaseAvailability", False), ("appStoreReviewScreenshot", False)):
            _, r = api("get", f"/v2/inAppPurchases/{iap}/{what}" + ("?limit=3" if many else ""))
            d = r.get("data")
            print(f"  {what}: {len(d) if isinstance(d, list) else ('あり' if d else 'なし')}")
        return 0

    # 2. 表示名と説明
    _, have = api("get", f"/v2/inAppPurchases/{iap}/inAppPurchaseLocalizations?limit=50")
    done = {x["attributes"]["locale"] for x in have.get("data", [])}
    for locale, lang in L["locales"].items():
        if locale in done:
            continue
        t = tip["text"][lang]
        api("post", "/v1/inAppPurchaseLocalizations", {"data": {
            "type": "inAppPurchaseLocalizations",
            "attributes": {"locale": locale, "name": t["name"], "description": t["description"]},
            "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap}}}}})
        print("  文言:", locale)

    # 3. 価格（¥200）
    _, sched = api("get", f"/v2/inAppPurchases/{iap}/iapPriceSchedule")
    if not sched.get("data"):
        _, points = api("get", f"/v2/inAppPurchases/{iap}/pricePoints?filter[territory]=JPN&limit=200")
        point = next((p for p in points.get("data", [])
                      if p["attributes"]["customerPrice"] in ("200", "200.00")), None)
        if point is None:
            print("  ! ¥200 の価格が見つからない")
            return 1
        api("post", "/v1/inAppPurchasePriceSchedules", {
            "data": {"type": "inAppPurchasePriceSchedules",
                     "relationships": {
                         "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap}},
                         "baseTerritory": {"data": {"type": "territories", "id": "JPN"}},
                         "manualPrices": {"data": [{"type": "inAppPurchasePrices", "id": "${p}"}]}}},
            "included": [{"type": "inAppPurchasePrices", "id": "${p}",
                          "attributes": {"startDate": None, "endDate": None},
                          "relationships": {"inAppPurchasePricePoint": {
                              "data": {"type": "inAppPurchasePricePoints", "id": point["id"]}}}}]})
        print("  価格: ¥200")

    # 4. 配信地域（アプリ本体に合わせる）
    _, avail = api("get", f"/v2/inAppPurchases/{iap}/inAppPurchaseAvailability")
    if not avail.get("data"):
        # **地域の ID は territoryAvailabilities の id ではない**（あれは合成キー）。
        # include=territory で付いてくる 3文字コード（JPN など）を使う
        _, app_av = api("get", f"/v2/appAvailabilities/{APP_ID}/territoryAvailabilities"
                               "?limit=200&include=territory")
        ok = {t["relationships"]["territory"]["data"]["id"]
              for t in app_av.get("data", []) if t["attributes"].get("available")}
        terrs = [t["id"] for t in app_av.get("included", []) if t["id"] in ok]
        api("post", "/v1/inAppPurchaseAvailabilities", {"data": {
            "type": "inAppPurchaseAvailabilities",
            "attributes": {"availableInNewTerritories": True},
            "relationships": {
                "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap}},
                "availableTerritories": {"data": [{"type": "territories", "id": t} for t in terrs]}}}})
        print(f"  配信地域: {len(terrs)} 地域")

    # 5. 審査用スクリーンショット
    _, shot = api("get", f"/v2/inAppPurchases/{iap}/appStoreReviewScreenshot")
    if not shot.get("data"):
        data = SHOT.read_bytes()
        _, made = api("post", "/v1/inAppPurchaseAppStoreReviewScreenshots", {"data": {
            "type": "inAppPurchaseAppStoreReviewScreenshots",
            "attributes": {"fileName": SHOT.name, "fileSize": len(data)},
            "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap}}}}})
        sid = made["data"]["id"]
        op = made["data"]["attributes"]["uploadOperations"][0]
        cmd = ["curl", "-sS", "-X", op["method"], op["url"], "--data-binary", f"@{SHOT}"]
        for h in op["requestHeaders"]:
            cmd += ["-H", f"{h['name']}: {h['value']}"]
        subprocess.run(cmd, check=True, capture_output=True)
        api("patch", f"/v1/inAppPurchaseAppStoreReviewScreenshots/{sid}", {"data": {
            "type": "inAppPurchaseAppStoreReviewScreenshots", "id": sid,
            "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
        print("  審査用スクショ: 入れた")

    _, s = api("get", f"/v2/inAppPurchases/{iap}")
    print("状態:", s["data"]["attributes"].get("state"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
