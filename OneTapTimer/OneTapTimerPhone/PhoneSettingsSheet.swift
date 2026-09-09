import SwiftUI
import OneTapTimerCore
import OneTapTimerUI

/// 時間を変えるシート。Watch と同じ部品を、指で押しやすい大きさで。
struct PhoneSettingsSheet: View {
    @Environment(Runner.self) private var runner
    @State private var draft: Int = DurationRule.standard

    var body: some View {
        VStack(spacing: 24) {
            DurationEditor(value: $draft, buttonSize: CGSize(width: 150, height: 64), spacing: 14,
                           valueSize: 72,
                           onStep: { runner.stepped(up: $0) })

            Spacer(minLength: 0)

            SettingsFooter(theme: runner.themeHex, number: runner.theme,
                           height: 58, spacing: 14,
                           onColor: { runner.cycleTheme() },
                           onDone: { runner.apply(duration: draft) })
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .padding(.top, 28)
        .onAppear { draft = runner.duration }
    }
}
