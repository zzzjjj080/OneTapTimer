# ワンタップタイマー（watchOS / iOS）

**開いた瞬間に始まるタイマー。** 90秒（変えられる）を、文字盤のコンプリケーションから一発で。
終わったら**一度だけ震えて止まる**。鳴り続けないので、放っておいてよい。

- 対象: watchOS 11.0 以降 / iOS 18.0 以降
- バンドルID: `com.zzzjjj080.OneTapTimer`（Watch は `.watchkitapp`、コンプリケーションは `.watchkitapp.Widget`）
- 英語名: One Tap Timer

## 動き

| 場面 | 何が起きるか |
|---|---|
| 開いた | 設定してある長さ（初期値 1分30秒）で**すぐ走り出す**。触覚 `.start` |
| 走っている | 画面全体の水位が下がる。**残りの秒だけを大きく**（`93`）、下に小さく `1:33`。最後の10秒は水が琥珀になる |
| 走っている画面をタップ | 何も起きない（誤タップで最初に戻らない） |
| 左上の ⏸ | **一時停止。** 水が灰色になり「一時停止中」と出る。ボタンが色つきの ▶ に変わり、押すと続きから |
| **クラウンを押す** | **止めて文字盤へ。** 予約した通知も前面を留めるセッションも消えるので、あとから何も起きない。画面の右端、クラウンの高さに「キャンセル ▶」と出ている |
| 腕を下ろした | タイマーはそのまま。**文字盤には戻らない**ので、終わりの合図もアプリ自身が正確に鳴らす |
| 終わった画面をタップ | 新しく始める |
| 終わったあと | 振動が鳴り終わって**約1秒でアプリを閉じ、文字盤に戻る**（Watch だけ）。その1秒のうちに「おわり」をタップすれば次が始まる |
| 上の中央の丸ボタン | 時間を変える。±10秒・±1分の4つと Digital Crown（1目盛り10秒）。「完了」で保存して最初から |
| 設定の色の丸 | 押すたびに 1→…→10→1。水・終わった画面・ボタン・文字盤のコンプリケーションの色が変わる |
| 文字盤のコンプリケーション | ストップウォッチのマークの下に**設定してある秒数**（`90`）。押すと開いて始まる |
| 終わった | 触覚を**一度だけ**（`.notification`×3 → `.success`）。画面が白く抜けて「おわり」。タップで最初から |
| 腕を下ろしていた | 終わる時刻に通知が1回（触覚つき）。前に出ている間は通知を出さず、自分で鳴らす |
| 開き直した | **アプリの外から開いたときだけ**始まる。腕を上げただけでは始まらない |

時間の範囲は 10秒〜60分。刻みは 10秒と 1分。

## なぜ iOS アプリがあるのか

**Xcode は watchOS のアーカイブを App Store へ出せない**（引き継ぎ書 4-91）。
iOS アプリを配信の器にして、その中に Watch アプリを入れて出す。
Watch 側に `WKRunsIndependentlyOfCompanionApp` を付けてあるので、使う人は iPhone アプリを入れずに Watch だけに入れられる。

器を空にはしない。**iPhone は「Watch のタイマーの見た目を決める器」。**（1.3 から。2026-09-27 本人決定）

1.2 までは同じタイマーが iPhone でも動いたが、外した。狭い Watch の画面に設定を積むより、
iPhone で選んで送るほうが手が早い。**Watch 側からは見た目を変えられない**（色ボタンも外した）。

見た目は番号の付いた選択肢（`Y1 C1 N1 …`）で表す。見本表は `./Tools-MakeCatalog.sh` で
`design/catalog-1.png`（文字盤）・`-2.png`（アプリの画面）を作り直す。
**番号は 1 から連番。抜けを作らない**（足し引きしたらその種類ぜんぶを振り直す。テストで固定）。

**主役は文字盤（コンプリケーション）。** 文字盤にいつも出ているのはこちらなので、先に並べる。

| 頭 | 種類 | 数 | 既定 |
|---|---|---|---|
| W | 中身（絵と数字・数字だけ・数字と単位・絵だけ） | 4 | W1 |
| I | 絵（ストップウォッチ・タイマー・砂時計・稲妻・しずく） | 5 | I1 |
| R | 輪（なし・細い・太い・点線） | 4 | R1 なし |
| V | 色の付け方（色つき・白・塗りつぶし） | 3 | V1 |
| U | 大きさ | 3 | U2 中 |
| J | 書体 | 3 | J1 丸ゴシック |

アプリの画面（走っている画面）は次の8種類。

| 頭 | 種類 | 数 | 既定 |
|---|---|---|---|
| Y | 減り方（水・輪・棒・色が薄れる） | 4 | Y1 水 |
| C | 色（文字盤にも効く） | 10 | C1 ティール |
| N | 数字（秒＋時計・秒だけ・時計だけ・出さない） | 4 | N1 |
| S | 大きさ | 4 | S3 大 |
| T | 書体 | 4 | T1 丸ゴシック |
| F | 文字の太さ | 3 | F3 太 |
| O | 縁取り（影・なし・黒ぶち） | 3 | O1 影 |
| P | 置き場所 | 3 | P1 真ん中 |

**1.3 で消した種類**（変えられなくてよい、と本人判断）：塗り方 G・向き D・地の色 B・
文字の色 K・終わりが近いとき L・終わった画面 E・目盛り M。
地は黒、水は上下グラデ、文字は白、終わり際は琥珀、終わったら白く抜ける、で固定。

- 送るのは `WCSession.updateApplicationContext`（**最新の1件だけ**が残り、相手が次に起きたときに届く）。
  App Group は同じ端末の中だけなので、これが無いと Watch には伝わらない
- 保存も送信も**1行の文字**。選択肢を足し引きしても、知らない番号はその項目だけ既定に落ちる
- **文字盤の丸は `DialFace` 1つ**。拡張（コンプリケーション）もアプリの見本も同じものを描く
  （拡張に `OneTapTimerCore` と `OneTapTimerUI` を繋いである）

## 中身

```
OneTapTimerCore/          UI に依存しないロジック。swift test で回る（25本）
  DurationRule.swift      範囲・刻み・プリセット・つまみの丸め
  TimerEngine.swift       「終わる時刻 − 今」で残りを出す。終わった瞬間を一度だけ返す
  TimeText.swift          秒 → 文字（切り上げ。大きい数字は秒だけ、小さく m:ss）
  PaletteHex.swift        色の数値とコントラスト比
OneTapTimerUI/            Watch と iPhone で共有する絵と動き（SwiftUI + UserNotifications だけ）。swift test で回る（7本）
  Runner.swift            開いたら始める／続き／おわりの判断。保存もここ
  DrainFace.swift         水位の画面。Canvas で描く（GeometryReader を使わない）
  DurationEditor.swift    時間を合わせる部品（＋−・チップ）
  EndNotifier.swift       終わる時刻の通知と、前に出ている間の抑え
  FaceDesign.swift        見た目の選択肢（Core 側）。番号と既定はここ
  DialFace.swift          文字盤の丸の中身。拡張とアプリの見本で共通
  DesignEditor.swift      見た目を決める画面（iPhone だけ）。選択肢は小さな見本と番号
  DesignSync.swift        iPhone → Watch へ見た目を送る（WCSession）
  Skin.swift / GearButton.swift
OneTapTimer/              Xcode プロジェクト
  Watch-Info.plist        同期グループの外に置く（中に置くとビルドが必ず落ちる）
  OneTapTimer/            watchOS アプリ（RunView / SettingsView / Haptics）
  OneTapTimerPhone/       iPhone 側（見た目を決める画面だけ）
  OneTapTimerWidget/      文字盤のコンプリケーション（押すとアプリが開く）
prototype/index.html      挙動と見た目を決めた HTML プロトタイプ
```

## 時間の測り方

`Timer` で1秒ずつ減らしていない。残りは常に**「終わる時刻 − 現在時刻」**。
画面が消えてもプロセスが落ちても、次に時刻を渡した瞬間に正しい値へ追いつく。
終わる時刻は UserDefaults に保存してあるので、開き直しても続きになる。

水位は `TimelineView(.animation)` で 30fps。常時表示（暗い画面）のときは1秒ごとに落とし、
数字は `Text(timerInterval:)` でシステムに描かせる（そのときだけ `0:45` の形になる）。

## 検証

```bash
cd OneTapTimerCore && swift test
cd OneTapTimerUI && swift test

# シミュレータ（他のスレッドと取り合わないよう、自分用に作った端末を UDID で指す）
W=$(cat .sim-watch)
SIMCTL_CHILD_OTT_SKIP_PERMISSION=1 SIMCTL_CHILD_OTT_STATE=running:45 \
  xcrun simctl launch "$W" com.zzzjjj080.OneTapTimer.watchkitapp
xcrun simctl io "$W" screenshot out.png
```

`OTT_STATE` は `running:秒` / `last:秒` / `done` / `settings`。`OTT_SKIP_PERMISSION=1` で通知の許可ダイアログを出さない。
どちらも DEBUG 構成にしか無い。

**通知の許可ダイアログはシミュレータの中で居座る。** アプリを消しても残る。出してしまったら
シミュレータを `shutdown` → `boot` する。

## 実機

```bash
./install-watch.sh    # Watch を腕に着けてロック解除。Wi-Fi 越しで入る
./install-phone.sh
```

Debug は自動署名（`-allowProvisioningUpdates`。Xcode にアカウントが入っている）。
Release は手動で、提出用のプロファイルは `./Tools-MakeProfile.py dist` が作る。

## コンプリケーションと App Group

コンプリケーションは別プロセスなので、設定した秒数と「走っているか」を
App Group（`group.com.zzzjjj080.OneTapTimer`）の UserDefaults で渡す。`OneTapTimerUI/SharedStore.swift` がキーの正。
拡張はパッケージを読まず、同じキーと `TimerEngine` の JSON を自前で読む（`OneTapTimerWidget.swift` の `SharedState`）。
アプリは保存のたびに `WidgetCenter.reloadAllTimelines()` を呼ぶ。走っている間は終わる時刻に2枚目のエントリを置き、
文字盤はそこで秒数の表示にひとりでに戻る。

App Group の作成は API に無い。自動署名で一度ビルドすると作られる（引き継ぎ書 4-28 の訂正）。

## 投げ銭をやめた（1.4）

**2026-09-30 本人決定（副業禁止のため、収入の入り口を無くす）。**

- `TipJar` / `TipSheet` と、Watch の ♡・iPhone のハートのボタンを外した
- 代わりに iPhone の設定のいちばん下に**1行のリンク**（[作者の他のアプリ](https://apps.apple.com/jp/developer/jin-nakamura/id6802013586)）。
  Watch には置かない（watchOS から App Store の開発者ページは開けない）
- **アプリは再び「通信しない」。** プライバシーのページ・掲載文・README の記述も戻した
  （投げ銭を入れたときに直した4か所をすべて見た）
- App Store Connect の課金アイテムは**別のスレッドで止める。** ここでは触らない
