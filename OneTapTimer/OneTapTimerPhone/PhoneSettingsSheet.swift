import SwiftUI
import OneTapTimerCore
import OneTapTimerUI

/// 時間を変えるシート。Watch と同じ部品を、指で押しやすい大きさで。
struct PhoneSettingsSheet: View {
    @Environment(Runner.self) private var runner
    @State private var draft: Int = DurationRule.standard
    @State private var tipJar = TipJar(productID: TipJar.oneTapTimer)
    @State private var showTip = false

    var body: some View {
        VStack(spacing: 24) {
            DurationEditor(value: $draft, theme: runner.themeHex, buttonSize: CGSize(width: 150, height: 64), spacing: 14,
                           valueSize: 110,
                           onStep: { runner.stepped(up: $0) })

            Spacer(minLength: 0)

            SettingsFooter(theme: runner.themeHex, number: runner.theme,
                           height: 58, spacing: 14,
                           onColor: { runner.cycleTheme() },
                           onDone: { runner.apply(duration: draft) },
                           onTip: { showTip = true })
                .padding(.horizontal, 20)

            Text(BuildStamp.text)
                .font(.system(size: 12, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(Color(hex: PaletteHex.ink).opacity(0.35))
                .padding(.bottom, 16)
        }
        .padding(.top, 28)
        .sheet(isPresented: $showTip) {
            TipSheet(tipJar: tipJar, theme: runner.themeHex) { showTip = false }
                .presentationDetents([.height(240)])
        }
        .onAppear {
            draft = runner.duration
            #if DEBUG
            // 撮影用。OTT_STATE=tip で投げ銭の画面まで開く（審査用スクショはこれを使う）
            if ProcessInfo.processInfo.environment["OTT_STATE"] == "tip" { showTip = true }
            #endif
        }
    }
}
