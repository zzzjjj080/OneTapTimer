import SwiftUI
import OneTapTimerCore
import OneTapTimerUI

/// 時間を変えるシート。Watch と同じ部品を、指で押しやすい大きさで。
struct PhoneSettingsSheet: View {
    @Environment(Runner.self) private var runner
    @State private var draft: Int = DurationRule.standard

    var body: some View {
        VStack(spacing: 28) {
            HStack {
                Button {
                    runner.closeSettings()
                } label: {
                    Text("戻る")
                        .font(.system(size: 17))
                        .foregroundStyle(Color(hex: PaletteHex.inkDim))
                        .frame(minWidth: 60, minHeight: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("back")
                Spacer()
            }
            .padding(.horizontal, 20)

            DurationEditor(value: $draft, compact: false, showsLabel: true,
                           stepSize: CGSize(width: 104, height: 60),
                           valueSize: 76, chipSize: 17,
                           onStep: { runner.stepped(up: $0) },
                           onPick: { runner.picked() })

            Spacer(minLength: 0)

            Button {
                runner.apply(duration: draft)
            } label: {
                Text("この時間で開始")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color(hex: PaletteHex.ground))
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(Capsule().fill(Color.accent))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .accessibilityIdentifier("go")
        }
        .padding(.top, 12)
        .onAppear { draft = runner.duration }
    }
}
