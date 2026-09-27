import SwiftUI
import OneTapTimerCore
import OneTapTimerUI

/// iPhone の画面。**1.3 からタイマーは無い。見た目を決める器。**
///
/// 選んだ瞬間に App Group へ保存し、`DesignSync` で Apple Watch へ送る。
/// 届くのは Watch アプリが次に起きたとき（すぐとは限らない）。
struct PhoneRootView: View {
    @Environment(Runner.self) private var runner
    @State private var tipJar = TipJar(productID: TipJar.oneTapTimer)
    @State private var showTip = false

    var body: some View {
        DesignEditor(design: Binding(get: { runner.design },
                                     set: { runner.apply(design: $0, send: true) }),
                     duration: runner.duration,
                     onTip: { showTip = true })
            .sheet(isPresented: $showTip) {
                TipSheet(tipJar: tipJar, theme: runner.themeHex) { showTip = false }
                    .presentationDetents([.height(240)])
            }
            .onAppear {
                #if DEBUG
                // 撮影用。OTT_STATE=tip で投げ銭の画面まで開く（審査用スクショはこれを使う）
                if ProcessInfo.processInfo.environment["OTT_STATE"] == "tip" { showTip = true }
                #endif
            }
            .preferredColorScheme(.dark)
    }
}
