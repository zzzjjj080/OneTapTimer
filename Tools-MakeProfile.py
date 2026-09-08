#!/usr/bin/env python3
"""バンドルIDの登録と、プロビジョニングプロファイルの作成。App Store Connect API だけで済む。

    ./Tools-MakeProfile.py dev     # 実機ビルド用（開発証明書＋登録済み端末）
    ./Tools-MakeProfile.py dist    # App Store 提出用（配布証明書）

3つのバンドルID（本体・Watch・コンプリケーション）に1枚ずつ作る。
プロファイルはバンドルIDごとに要る（引き継ぎ書 4-80）。名前は project.pbxproj の
PROVISIONING_PROFILE_SPECIFIER と一致させる。

有効期限は1年。切れたら、端末を足したら、もう一度走らせる。
"""
import base64
import json
import os
import pathlib
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
ASC = HERE / "Tools-ASC.py"
APP = "com.zzzjjj080.OneTapTimer"

# (バンドルID, 登録名, dev のプロファイル名, dist のプロファイル名)
TARGETS = [
    (APP, "OneTapTimer", "OneTapTimer iOS Dev", "OneTapTimer App Store"),
    (APP + ".watchkitapp", "OneTapTimer Watch", "OneTapTimer Watch Dev", "OneTapTimer Watch App Store"),
    (APP + ".watchkitapp.Widget", "OneTapTimer WatchWidget", "OneTapTimer WatchWidget Dev", "OneTapTimer WatchWidget App Store"),
]


def asc(method, path, body=None):
    cmd = [sys.executable, str(ASC), method, path] + ([body] if body else [])
    out = subprocess.run(cmd, capture_output=True, text=True).stdout
    head, _, rest = out.partition("\n")
    if not head.startswith("HTTP 2"):
        raise SystemExit(f"{method} {path} で失敗しました:\n{out}")
    return json.loads(rest) if rest.strip() else {}


def ensure_bundle(identifier, name, known):
    if identifier in known:
        return known[identifier]
    body = json.dumps({"data": {"type": "bundleIds", "attributes": {
        "identifier": identifier, "name": name, "platform": "IOS"}}})
    bid = asc("post", "/v1/bundleIds", body)["data"]["id"]
    print(f"登録: {identifier} ({bid})")
    return bid


def main():
    kind = sys.argv[1] if len(sys.argv) > 1 else "dev"
    if kind not in ("dev", "dist"):
        raise SystemExit("dev か dist を指定してください")

    known = {x["attributes"]["identifier"]: x["id"]
             for x in asc("get", "/v1/bundleIds?limit=200")["data"]}
    cert_type = "DEVELOPMENT" if kind == "dev" else "DISTRIBUTION"
    certs = [x["id"] for x in asc("get", "/v1/certificates?limit=50")["data"]
             if x["attributes"]["certificateType"] == cert_type]
    if not certs:
        raise SystemExit(f"{cert_type} の証明書がありません")
    devices = [] if kind == "dist" else [
        x["id"] for x in asc("get", "/v1/devices?limit=200")["data"]
        if x["attributes"]["status"] == "ENABLED"]
    profile_type = "IOS_APP_DEVELOPMENT" if kind == "dev" else "IOS_APP_STORE"
    existing = asc("get", "/v1/profiles?limit=200")["data"]

    for identifier, name, dev_name, dist_name in TARGETS:
        profile_name = dev_name if kind == "dev" else dist_name
        bid = ensure_bundle(identifier, name, known)
        for x in existing:
            if x["attributes"]["name"] == profile_name:
                asc("delete", f"/v1/profiles/{x['id']}")
                print("古いものを消しました:", profile_name)
        rel = {"bundleId": {"data": {"type": "bundleIds", "id": bid}},
               "certificates": {"data": [{"type": "certificates", "id": c} for c in certs]}}
        if devices:
            rel["devices"] = {"data": [{"type": "devices", "id": d} for d in devices]}
        body = json.dumps({"data": {"type": "profiles",
                                    "attributes": {"name": profile_name, "profileType": profile_type},
                                    "relationships": rel}})
        a = asc("post", "/v1/profiles", body)["data"]["attributes"]
        raw = base64.b64decode(a["profileContent"])
        for folder in ("~/Library/MobileDevice/Provisioning Profiles",
                       "~/Library/Developer/Xcode/UserData/Provisioning Profiles"):
            p = pathlib.Path(os.path.expanduser(folder))
            p.mkdir(parents=True, exist_ok=True)
            (p / f"{a['uuid']}.mobileprovision").write_bytes(raw)
        print(f"✅ {a['name']}（{a['uuid']}）/ 期限 {a['expirationDate'][:10]}")


if __name__ == "__main__":
    main()
