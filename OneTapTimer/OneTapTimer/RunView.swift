import SwiftUI
import WatchKit
import OneTapTimerCore
import OneTapTimerUI

/// 走っている画面。**止めるのはクラウン**（押すと止まって文字盤へ戻る）。
/// 走っている最中のタップは何もしない。終わった画面ではタップで始める。
/// 上の中央に、時間を変える入口。
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
                // 画面の外、右のここにクラウンがある。**文字だけでは、どこを押すのか分からない。**
                // クラウンを左に設定していても画面ごと180度回るので、右端で合っている
                .overlay(alignment: .topTrailing) {
                    if !runner.engine.isFinished {
                        crownHint
                    }
                }
                .overlay(alignment: .bottom) { debugStatus }

            // 上の中央。システムの時刻は右上に出るので、真ん中は空いている
            SettingButton(skin: Skin.of(runner.engine, at: .now, theme: runner.themeHex), size: 42) {
                runner.openSettings()
            }
            .padding(.top, 6)
        }
        // 安全領域を外すのはここ1か所だけ。内側で重ねて外すと、かえって狭くなる
        .ignoresSafeArea()
    }

    /// **動作確認用。** 前面を留めるセッションが効いているかを、実機の画面で見る。
    /// Mac から Watch への接続が不安定で記録を吸い出せないので、画面に出して本人に読んでもらう。
    /// **リリース構成には入らない。**
    @ViewBuilder
    private var debugStatus: some View {
        #if DEBUG
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            let keeping = runner.keeper?.isKeeping == true
            Text((keeping ? "● 留め中\n" : "○ 留めなし\n") + (runner.keeper?.lastEvent ?? "keeperなし"))
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(keeping ? Color.green : Color.red)
                .lineLimit(5)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.bottom, 4)
        }
        #endif
    }

    /// 「キャンセル ▶」。**クラウンの高さに、画面の右端いっぱいまで寄せて置く。**
    /// クラウンは右側の、上から3割ほどのところにある。矢印がその外側を指す。
    private var crownHint: some View {
        HStack(spacing: 2) {
            Text("キャンセル")
                .font(.system(size: 11, weight: .medium))
            Image(systemName: "arrowtriangle.right.fill")
                .font(.system(size: 9, weight: .black))
        }
        .foregroundStyle(Color(hex: PaletteHex.ink).opacity(0.7))
        .padding(.top, WKInterfaceDevice.current().screenBounds.height * 0.26)
        .accessibilityHidden(true)
    }

    /// 動いている間は毎秒2回、常時表示では1秒ごとに描き直す。常時表示では
    /// 数字はシステムに描かせる（アプリのコードが止まっても進む）。
    @ViewBuilder
    private var face: some View {
        if dim {
            TimelineView(.periodic(from: .now, by: 1)) { t in
                DrainFace(engine: runner.engine, now: t.date, theme: runner.themeHex, metrics: .watch, liveDigits: false)
            }
        } else {
            // **毎秒2回だけ描き直す。** 30fps で描いていたら、前面を留めるセッションが
            // 30秒ほどで打ち切られた疑いが強い（Apple「Using extended runtime sessions」：
            // CPU を使い続けるとシステムがセッションを取り消すことがある）。
            // 90秒で水位が動くのは1秒に1%ほどなので、2回で見た目は変わらない
            TimelineView(.periodic(from: .now, by: 0.5)) { t in
                DrainFace(engine: runner.engine, now: t.date, theme: runner.themeHex, metrics: .watch, liveDigits: true)
            }
        }
    }
}
