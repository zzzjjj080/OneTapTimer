import SwiftUI
import OneTapTimerCore

/// 時間を合わせる部品。見出し・大きな値・＋−・チップ。
///
/// 決定や戻るのボタンは持たない。**置き場所が Watch と iPhone で違う**ため、外側で足す。
/// Digital Crown も外側で付ける（`value` を書き換えればここは追従する）。
public struct DurationEditor: View {
    @Binding public var value: Int
    /// 小さい画面（40mm など）ではチップを1行に減らす
    public var compact: Bool
    /// 「時間」の見出し。40mm では高さが足りないので消す
    public var showsLabel: Bool
    public var stepSize: CGSize
    public var valueSize: CGFloat
    public var chipSize: CGFloat
    public var onStep: (Bool) -> Void
    public var onPick: () -> Void

    public init(value: Binding<Int>, compact: Bool, showsLabel: Bool = true,
                stepSize: CGSize, valueSize: CGFloat, chipSize: CGFloat,
                onStep: @escaping (Bool) -> Void, onPick: @escaping () -> Void) {
        _value = value
        self.compact = compact; self.showsLabel = showsLabel; self.stepSize = stepSize
        self.valueSize = valueSize; self.chipSize = chipSize
        self.onStep = onStep; self.onPick = onPick
    }

    private var presets: [Int] { compact ? DurationRule.presetsCompact : DurationRule.presets }

    public var body: some View {
        VStack(spacing: valueSize * 0.2) {
            if showsLabel {
                Text("時間", bundle: .module)
                    .font(.system(size: chipSize, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(Color(hex: PaletteHex.inkDim))
            }

            valueText
                .accessibilityIdentifier("value")

            HStack(spacing: stepSize.width * 0.2) {
                StepButton(systemName: "minus", isUp: false, size: stepSize) {
                    change(DurationRule.stepped(value, up: false), up: false)
                }
                StepButton(systemName: "plus", isUp: true, size: stepSize) {
                    change(DurationRule.stepped(value, up: true), up: true)
                }
            }

            chips
        }
    }

    /// `1分30秒` の「1」と「30」を大きく、単位を小さく。
    private var valueText: some View {
        let m = value / 60, s = value % 60
        let big = Font.system(size: valueSize, weight: .heavy, design: .rounded)
        let small = Font.system(size: valueSize * 0.38, weight: .semibold)
        return HStack(alignment: .firstTextBaseline, spacing: 1) {
            if m > 0 {
                Text("\(m)").font(big)
                Text("分", bundle: .module).font(small)
            }
            if s > 0 || m == 0 {
                Text(m > 0 ? String(format: "%02d", s) : "\(s)").font(big)
                Text("秒", bundle: .module).font(small)
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundStyle(Color(hex: PaletteHex.ink))
        .contentTransition(.numericText())
        .animation(.snappy(duration: 0.2), value: value)
    }

    private var chips: some View {
        let rows: [[Int]] = compact ? [presets] : [Array(presets.prefix(3)), Array(presets.dropFirst(3))]
        return VStack(spacing: chipSize * 0.4) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: chipSize * 0.5) {
                    ForEach(row, id: \.self) { p in
                        Button {
                            change(p, up: p > value)
                            onPick()
                        } label: {
                            Text(TimeText.brief(p))
                                .font(.system(size: chipSize, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .padding(.horizontal, chipSize * 0.8)
                                .frame(minHeight: chipSize * 2.2)
                                // Button は中の文字色を上書きするので、自分で指定し直す
                                .foregroundStyle(p == value ? Color(hex: PaletteHex.ground)
                                                            : Color(hex: PaletteHex.inkDim))
                                .background(Capsule().fill(p == value ? Color.accent : Color.well))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("chip-\(p)")
                    }
                }
            }
        }
    }

    private func change(_ new: Int, up: Bool) {
        let v = DurationRule.clamp(new)
        guard v != value else { return }
        value = v
        onStep(up)
    }
}

/// ＋ − のボタン。**押している間、増え続ける（減り続ける）。**
///
/// `Button` ではなく長押しで受けている。`Button` は指を離したときにしか呼ばれないので、
/// 押しっぱなしを拾えない。`pressing:` なら押した瞬間と離した瞬間の両方が来る。
struct StepButton: View {
    let systemName: String
    let isUp: Bool
    let size: CGSize
    let step: () -> Void

    @State private var holding: Task<Void, Never>?

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size.height * 0.55, weight: .bold))
            .foregroundStyle(Color(hex: PaletteHex.ink))
            .frame(width: size.width, height: size.height)
            .background(Capsule().fill(Color.well.opacity(holding == nil ? 1 : 1.6)))
            .contentShape(Capsule())
            // 押し続けても `perform` が呼ばれないよう、長い時間を指定しておく。
            .onLongPressGesture(minimumDuration: 3600, pressing: { pressing in
                if pressing { begin() } else { end() }
            }, perform: {})
            .onDisappear { end() }
            .accessibilityIdentifier(isUp ? "plus" : "minus")
    }

    private func begin() {
        end()
        step()
        holding = Task { @MainActor in
            try? await Task.sleep(for: .seconds(HoldRepeat.delay))
            var done = 0
            while !Task.isCancelled {
                step()
                try? await Task.sleep(for: .seconds(HoldRepeat.interval(after: done)))
                done += 1
            }
        }
    }

    private func end() {
        holding?.cancel()
        holding = nil
    }
}
