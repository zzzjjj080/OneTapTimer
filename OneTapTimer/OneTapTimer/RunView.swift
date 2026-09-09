import SwiftUI
import WatchKit
import OneTapTimerUI

/// 走っている画面。**長押しでキャンセル。** 走っている最中のタップは何もしない（終わった画面ではタップで始める）。
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
                .onLongPressGesture(minimumDuration: 0.7) { runner.cancel() }
                .accessibilityIdentifier("face")

            // 上の中央。時刻は右上に出るので、少し左に寄せて重ねない
            SettingPill(skin: Skin.of(runner.engine, at: .now, theme: runner.themeHex),
                        duration: runner.duration, height: 30) {
                runner.openSettings()
            }
            .padding(.top, 8)
            .padding(.trailing, 36)
        }
        // 安全領域を外すのはここ1か所だけ。内側で重ねて外すと、かえって狭くなる
        .ignoresSafeArea()
    }

    /// 動いている間は 30fps で水位を動かす。常時表示では1秒ごとにして、
    /// 数字はシステムに描かせる（アプリのコードが止まっても進む）。
    @ViewBuilder
    private var face: some View {
        if dim {
            TimelineView(.periodic(from: .now, by: 1)) { t in
                DrainFace(engine: runner.engine, now: t.date, theme: runner.themeHex, metrics: .watch, liveDigits: false)
            }
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: runner.engine.isFinished)) { t in
                DrainFace(engine: runner.engine, now: t.date, theme: runner.themeHex, metrics: .watch, liveDigits: true)
            }
        }
    }
}
