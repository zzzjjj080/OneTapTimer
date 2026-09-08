import SwiftUI
import WatchKit
import OneTapTimerCore
import OneTapTimerUI

/// 時間を変える画面。＋−・チップ・Digital Crown のどれでも。
struct SettingsView: View {
    @Environment(Runner.self) private var runner

    @State private var draft: Int = DurationRule.standard
    // Digital Crown は Double でしか回らないので、整数とは別に持つ
    @State private var crown: Double = Double(DurationRule.standard)
    @FocusState private var focused: Bool

    private var screen: CGSize { WKInterfaceDevice.current().screenBounds.size }
    /// 42mm 以下はチップを1行に
    private var compact: Bool { screen.height < 230 }
    /// 40mm はさらに詰める
    private var tiny: Bool { screen.height < 210 }
    /// 上に空ける高さ。ここにシステムの時計と「戻る」が出る
    private var clockReserve: CGFloat { tiny ? 20 : 24 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(hex: PaletteHex.ground).ignoresSafeArea()

            VStack(spacing: 0) {
                DurationEditor(value: $draft, compact: compact, showsLabel: !tiny,
                               stepSize: CGSize(width: tiny ? 46 : 52, height: tiny ? 30 : 36),
                               valueSize: tiny ? 32 : 40, chipSize: tiny ? 10 : 10.5,
                               onStep: { up in runner.stepped(up: up); crown = Double(draft) },
                               onPick: { runner.picked(); crown = Double(draft) })

                Spacer(minLength: 4)

                Button {
                    runner.apply(duration: draft)
                } label: {
                    Text("この時間で開始")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(0.5)
                        // 塗りがティールなので、文字は黒。こちらのほうが読める
                        .foregroundStyle(Color(hex: PaletteHex.ground))
                        .frame(maxWidth: .infinity, minHeight: tiny ? 30 : 34)
                        .background(Capsule().fill(Color.accent))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("go")
            }
            .padding(.top, clockReserve)
            .padding(.horizontal, 12)
            .padding(.bottom, tiny ? 6 : 8)

            Button {
                runner.closeSettings()
            } label: {
                Text("← 戻る")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(hex: PaletteHex.inkDim))
                    .frame(width: 60, height: 24, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.leading, 12)
            .padding(.top, 6)
            .accessibilityIdentifier("back")
        }
        .ignoresSafeArea()
        .focusable()
        .focused($focused)
        .digitalCrownRotation($crown,
                              from: Double(DurationRule.minimum), through: Double(DurationRule.maximum),
                              by: 1, sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true)
        // つまみ側からは刻みに乗せて受ける。つまみの値は書き戻さない（書き戻すと回している最中に引き戻される）
        .onChange(of: crown) { _, v in
            let s = DurationRule.snapped(v)
            if s != draft { draft = s }
        }
        .onAppear {
            draft = runner.duration
            crown = Double(runner.duration)
            focused = true
        }
    }
}
