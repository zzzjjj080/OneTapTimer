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
| 走っている | 画面全体の水位が下がる。1分を切ったら**秒だけ**を大きく出す。最後の10秒は水が琥珀になる |
| 走っている画面をタップ | 何も起きない（誤タップで最初に戻らない） |
| 長押し（0.7秒） | **キャンセル**。画面が白くなり「キャンセル」。下端に「長押しでキャンセル」と書いてある |
| **クラウンを押して出た** | **キャンセルして文字盤へ。** 予約した通知も消えるので、あとから鳴らない |
| 腕を下ろした | タイマーはそのまま。終わりは通知が知らせる（こちらのコードは暗い間ほとんど動けないため） |
| 終わった／キャンセルした画面をタップ | 新しく始める |
| 上の中央の丸ボタン | 時間を変える。±10秒・±1分の4つと Digital Crown（1目盛り10秒）。「完了」で保存して最初から |
| 設定の色の丸 | 押すたびに 1→…→10→1。水・終わった画面・ボタン・文字盤のコンプリケーションの色が変わる |
| 終わった | 触覚を**一度だけ**（`.notification`×3 → `.success`）。画面が白く抜けて「おわり」。タップで最初から |
| 腕を下ろしていた | 終わる時刻に通知が1回（触覚つき）。前に出ている間は通知を出さず、自分で鳴らす |
| 開き直した | **アプリの外から開いたときだけ**始まる。腕を上げただけでは始まらない。自然に終わってから30秒以内なら「おわり」のまま |

時間の範囲は 10秒〜60分。刻みは 10秒と 1分。

## なぜ iOS アプリがあるのか

**Xcode は watchOS のアーカイブを App Store へ出せない**（引き継ぎ書 4-91）。
iOS アプリを配信の器にして、その中に Watch アプリを入れて出す。
Watch 側に `WKRunsIndependentlyOfCompanionApp` を付けてあるので、使う人は iPhone アプリを入れずに Watch だけに入れられる。

器を空にはしない。**同じワンタップタイマーが iPhone でも動く。** 動きは `OneTapTimerUI` の `Runner` を両方で共有している。

## 中身

```
OneTapTimerCore/          UI に依存しないロジック。swift test で回る（25本）
  DurationRule.swift      範囲・刻み・プリセット・つまみの丸め
  TimerEngine.swift       「終わる時刻 − 今」で残りを出す。終わった瞬間を一度だけ返す
  TimeText.swift          秒 → 文字（切り上げ。1分を切ったら秒だけ）
  PaletteHex.swift        色の数値とコントラスト比
OneTapTimerUI/            Watch と iPhone で共有する絵と動き（SwiftUI + UserNotifications だけ）。swift test で回る（7本）
  Runner.swift            開いたら始める／続き／おわりの判断。保存もここ
  DrainFace.swift         水位の画面。Canvas で描く（GeometryReader を使わない）
  DurationEditor.swift    時間を合わせる部品（＋−・チップ）
  EndNotifier.swift       終わる時刻の通知と、前に出ている間の抑え
  Skin.swift / GearButton.swift
OneTapTimer/              Xcode プロジェクト
  Watch-Info.plist        同期グループの外に置く（中に置くとビルドが必ず落ちる）
  OneTapTimer/            watchOS アプリ（RunView / SettingsView / Haptics）
  OneTapTimerPhone/       iPhone 側
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
