import SwiftUI
import WatchKit
import OneTapTimerUI

/// 走っている画面。**画面のどこを押しても最初から。** 左上の歯車だけが例外。
struct RunView: View {
    @Environment(Runner.self) private var runner
    /// 常時表示（腕を下ろして暗くなった状態）
    @Environment(\.isLuminanceReduced) private var dim

    var body: some View {
        ZStack(alignment: .topLeading) {
            face
                .contentShape(Rectangle())
                .onTapGesture { runner.restart() }
                .accessibilityIdentifier("face")

            // 上部・左。時刻は右上に出るので、左は空いている
            GearButton(skin: Skin.of(runner.engine, at: .now), size: 34) {
                runner.openSettings()
            }
            .padding(.leading, 10)
            .padding(.top, 8)
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
                DrainFace(engine: runner.engine, now: t.date, metrics: .watch, liveDigits: false)
            }
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: runner.engine.isFinished)) { t in
                DrainFace(engine: runner.engine, now: t.date, metrics: .watch, liveDigits: true)
            }
        }
    }
}
