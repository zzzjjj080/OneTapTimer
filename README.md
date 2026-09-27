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
| 設定のハート | **コーヒー1杯（¥200）を送る。** 消耗型なので何度でも送れる。送ってもアプリの機能は何も変わらない。金額は StoreKit が返す表示価格をそのまま出す |
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

見た目は番号の付いた選択肢（`Y1 C1 G1 …`）で表す。見本表は `./Tools-MakeCatalog.sh` で
`design/catalog-1.png`・`-2.png` を作り直す。**番号は 1 から連番。抜けを作らない**
（足し引きしたらその種類ぜんぶを振り直す。テストで固定している）。

| 頭 | 種類 | 数 | 既定 |
|---|---|---|---|
| Y | 減り方（水・輪・棒・色が薄れる） | 4 | Y1 水 |
| C | 色 | 10 | C1 ティール |
| G | 塗り方（上下グラデ・単色・進むほど濃く） | 3 | G1 |
| D | 減る向き（下・上・左・右） | 4 | D1 下へ |
| B | 地の色（黒・濃い灰・色の濃い側・白） | 4 | B1 黒 |
| N | 数字（秒＋時計・秒だけ・時計だけ・出さない） | 4 | N1 |
| S | 大きさ | 4 | S3 大 |
| T | 書体 | 4 | T1 丸ゴシック |
| F | 文字の太さ | 3 | F3 太 |
| K | 文字の色 | 5 | K1 白 |
| O | 縁取り（影・なし・黒ぶち） | 3 | O1 影 |
| P | 置き場所 | 3 | P1 真ん中 |
| L | 終わりが近いとき（琥珀・変えない・赤・点滅） | 4 | L1 琥珀 |
| E | 終わった画面（白く抜ける・暗いまま・色で埋める） | 3 | E1 |
| M | 目盛り | 3 | M1 なし |

- 送るのは `WCSession.updateApplicationContext`（**最新の1件だけ**が残り、相手が次に起きたときに届く）。
  App Group は同じ端末の中だけなので、これが無いと Watch には伝わらない
- 保存も送信も**1行の文字**。選択肢を足し引きしても、知らない番号はその項目だけ既定に落ちる
- **読めない組み合わせは作らせない。** 地に対して薄い文字は、コントラスト比を見て濃い側へ落とす

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
