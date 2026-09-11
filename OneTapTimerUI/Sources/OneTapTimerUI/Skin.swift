import SwiftUI
import OneTapTimerCore

/// 画面の色。**状態（走っている／終わりが近い／終わった）× 色の組（1〜10）**で決まる。
///
/// 個々の場所で `if isDone { ... }` と書き分けると必ず抜けが出るので、
/// 状態ごとに「地・水・数字・弱い文字」を組で持たせる。
public struct Skin: Sendable, Equatable {
    public enum State: Sendable { case running, finalStretch, done }

    public var state: State
    public var theme: ThemeHex

    public init(state: State, theme: ThemeHex) { self.state = state; self.theme = theme }

    /// **止めたときは `.done` にしない。** クラウンで出ていく瞬間に画面が白く光ってしまう。
    /// 止めた画面は「満タンで待っている」見た目にして、次に開いたときと地続きにする。
    public static func of(_ engine: TimerEngine, at now: Date, theme: ThemeHex) -> Skin {
        if engine.isFinished && !engine.isCancelled { return Skin(state: .done, theme: theme) }
        return Skin(state: engine.isFinalStretch(at: now) ? .finalStretch : .running, theme: theme)
    }

    public var isDone: Bool { state == .done }

    public var ground: Color {
        isDone ? Color(hex: theme.doneGround) : Color(hex: PaletteHex.ground)
    }

    public var liquidTop: Color {
        Color(hex: state == .finalStretch ? theme.lastTop : theme.liquidTop)
    }

    public var liquidBottom: Color {
        Color(hex: state == .finalStretch ? theme.lastBottom : theme.liquidBottom)
    }

    public var ink: Color {
        isDone ? Color(hex: theme.doneInk) : Color(hex: PaletteHex.ink)
    }

    public var inkDim: Color {
        isDone ? Color(hex: theme.doneInkDim) : Color(hex: PaletteHex.ink).opacity(0.75)
    }

    /// ボタンなどの強調色。色の組の明るいほう
    public var accent: Color { Color(hex: theme.liquidTop) }

    /// 設定への入口の丸。地に溶ける薄いガラス。
    public var glass: Color {
        isDone ? Color(hex: theme.doneInk).opacity(0.08) : .white.opacity(0.14)
    }

    public var glassEdge: Color {
        isDone ? Color(hex: theme.doneInk).opacity(0.14) : .white.opacity(0.18)
    }

    public var glassInk: Color {
        isDone ? Color(hex: theme.doneInkDim) : .white.opacity(0.8)
    }
}

extension Color {
    public init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    /// 設定画面の押せるもの（色の組に関わらず同じ）
    public static let well = Color(hex: PaletteHex.well)
}
