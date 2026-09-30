import SwiftUI
import OneTapTimerCore
import OneTapTimerUI

/// iPhone の画面。**1.3 からタイマーは無い。見た目を決める器。**
///
/// 選んだ瞬間に App Group へ保存し、`DesignSync` で Apple Watch へ送る。
/// 届くのは Watch アプリが次に起きたとき（すぐとは限らない）。
///
/// **1.4 で投げ銭をやめた**（2026-09-30 本人決定）。いちばん下は「作者の他のアプリ」への1行のリンク。
struct PhoneRootView: View {
    @Environment(Runner.self) private var runner

    var body: some View {
        DesignEditor(design: Binding(get: { runner.design },
                                     set: { runner.apply(design: $0, send: true) }),
                     duration: runner.duration)
            .onAppear {
                #if DEBUG
                // 撮影用。OTT_DESIGN="Y2 C5 …" で見た目を決め打ちにする
                if let text = ProcessInfo.processInfo.environment["OTT_DESIGN"] {
                    runner.apply(design: FaceDesign(text: text))
                }
                #endif
            }
            .preferredColorScheme(.dark)
    }
}
