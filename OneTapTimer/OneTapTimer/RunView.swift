import SwiftUI
import WatchKit
import OneTapTimerCore
import OneTapTimerUI

/// 走っている画面。**止めるのはクラウン**（押すと止まって文字盤へ戻る）。
/// 走っている最中のタップは何もしない。終わった画面ではタップで始める。
/// 上の中央に、時間を変える入口。左上に一時停止。
struct RunView: View {
    @Environment(Runner.self) private var runner
    /// 常時表示（腕を下ろして暗くなった状態）
    @Environment(\.isLuminanceReduced) private var dim

    var body: some View {
        ZStack(alignment: .top) {
            face
                .contentShape(Rectangle())
                .onTapGesture { runner.startAgain() }
                .accessibilityIdentifier("face")
                // 画面の外、クラウンのある側に置く。**文字だけでは、どこを押すのか分からない。**
                // クラウンを左にしている人は時計を逆さに着けていて、画面は180度回るが
                // クラウンは装着者から見て**左下**に来る（右上のままだと反対側を指す）
                .overlay(alignment: crownOnLeft ? .bottomLeading : .topTrailing) {
                    if !runner.engine.isFinished {
                        crownHint
                    }
                }

            // 上の中央。システムの時刻は右上に出るので、真ん中は空いている
            // 押せる余白ぶん外へ寄せて置き、見た目の位置は変えない
            SettingButton(skin: Skin.of(runner.engine, at: .now, theme: runner.themeHex),
                          size: settingsSize, hitPadding: hitPadding) {
                runner.openSettings()
            }
            .padding(.top, buttonsTop - hitPadding)

            // 左上。**一時停止**（あまり使わないので隅に）。角の丸みに掛からないよう少し内側へ
            if !runner.engine.isFinished {
                PauseButton(skin: Skin.of(runner.engine, at: .now, theme: runner.themeHex),
                            isPaused: runner.engine.isPaused, size: pauseSize, hitPadding: hitPadding) {
                    runner.togglePause()
                }
                .padding(.leading, pauseLeading - hitPadding)
                // 設定の丸と縦の中心をそろえる
                .padding(.top, buttonsTop + (settingsSize - pauseSize) / 2 - hitPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        // 安全領域を外すのはここ1か所だけ。内側で重ねて外すと、かえって狭くなる
        .ignoresSafeArea()
    }

    // MARK: - 上のボタンの大きさ（2026-09-13：「押せる範囲を広く」と言われて大きくした）

    private var screenWidth: CGFloat { WKInterfaceDevice.current().screenBounds.width }
    /// 設定の丸。画面の幅の 23%（46mm で 48pt。前は 42pt）
    private var settingsSize: CGFloat { screenWidth * 0.23 }
    /// 一時停止の丸。画面の幅の 20%、ただし 36pt は下回らない（46mm で 42pt。前は 36pt）
    private var pauseSize: CGFloat { max(36, screenWidth * 0.2) }
    private var pauseLeading: CGFloat { 12 }
    private var buttonsTop: CGFloat { 6 }
    /// **見た目の丸の外側に足す、押せる余白。** 最大 8pt。
    /// 2つのボタンの押せる範囲が重なると、間を押したときにどちらになるか分からないので、
    /// 丸と丸のすき間の半分より手前で止める（40mm では 6pt ほどになる）
    private var hitPadding: CGFloat {
        let settingsLeft = (screenWidth - settingsSize) / 2
        let pauseRight = pauseLeading + pauseSize
        return max(0, min(8, (settingsLeft - pauseRight) / 2 - 1))
    }

    /// クラウンが装着者から見て左にあるか。**時計の設定（一般 → 向き）をそのまま読む**ので、
    /// アプリ側に設定は要らない。
    private var crownOnLeft: Bool {
        #if DEBUG
        // 撮影・確認用。シミュレータでは向きを変えにくいので、起動引数 -OTTCrownLeft YES で左にする
        if UserDefaults.standard.bool(forKey: "OTTCrownLeft") { return true }
        #endif
        return WKInterfaceDevice.current().crownOrientation == .left
    }

    /// 「キャンセル ▶」。**クラウンの高さに、画面の端いっぱいまで寄せて置く。**
    /// クラウンは右側の上から3割ほど。左のときは180度回った位置＝左側の下から3割ほど。
    /// 矢印がその外側を指す。
    private var crownHint: some View {
        HStack(spacing: 2) {
            if crownOnLeft {
                Image(systemName: "arrowtriangle.left.fill")
                    .font(.system(size: 9, weight: .black))
            }
            Text("キャンセル")
                .font(.system(size: 11, weight: .medium))
            if !crownOnLeft {
                Image(systemName: "arrowtriangle.right.fill")
                    .font(.system(size: 9, weight: .black))
            }
        }
        .foregroundStyle(Color(hex: PaletteHex.ink).opacity(0.7))
        .padding(crownOnLeft ? .bottom : .top, WKInterfaceDevice.current().screenBounds.height * 0.26)
        .accessibilityHidden(true)
    }

    /// 動いている間は毎秒2回、常時表示では1秒ごとに描き直す。常時表示では
    /// 数字はシステムに描かせる（アプリのコードが止まっても進む）。
    @ViewBuilder
    private var face: some View {
        if dim {
            TimelineView(.periodic(from: .now, by: 1)) { t in
                DrainFace(engine: runner.engine, now: t.date, theme: runner.themeHex, metrics: .watch)
            }
        } else {
            // **毎秒2回だけ描き直す。** 30fps で描いていたら、前面を留めるセッションが
            // 30秒ほどで打ち切られた疑いが強い（Apple「Using extended runtime sessions」：
            // CPU を使い続けるとシステムがセッションを取り消すことがある）。
            // 90秒で水位が動くのは1秒に1%ほどなので、2回で見た目は変わらない
            TimelineView(.periodic(from: .now, by: 0.5)) { t in
                DrainFace(engine: runner.engine, now: t.date, theme: runner.themeHex, metrics: .watch)
            }
        }
    }
}
