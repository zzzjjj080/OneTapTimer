import SwiftUI
import OneTapTimerCore

/// 画面の3状態。色はここで一括して決める。
///
/// 個々の場所で `if isDone { ... }` と書き分けると必ず抜けが出るので、
/// 状態ごとに「地・水・数字・弱い文字」を組で持たせる。
public enum Skin: Sendable, Equatable {
    case running, finalStretch, done

    public static func of(_ engine: TimerEngine, at now: Date) -> Skin {
        if engine.isFinished { return .done }
        return engine.isFinalStretch(at: now) ? .finalStretch : .running
    }

    public var ground: Color {
        self == .done ? Color(hex: PaletteHex.doneGround) : Color(hex: PaletteHex.ground)
    }

    public var liquidTop: Color {
        Color(hex: self == .finalStretch ? PaletteHex.lastTop : PaletteHex.liquidTop)
    }

    public var liquidBottom: Color {
        Color(hex: self == .finalStretch ? PaletteHex.lastBottom : PaletteHex.liquidBottom)
    }

    public var ink: Color {
        self == .done ? Color(hex: PaletteHex.doneInk) : Color(hex: PaletteHex.ink)
    }

    public var inkDim: Color {
        self == .done ? Color(hex: PaletteHex.doneInkDim) : Color(hex: PaletteHex.ink).opacity(0.75)
    }

    /// 歯車の丸。地に溶ける薄いガラス。
    public var glass: Color {
        self == .done ? Color(hex: PaletteHex.doneInk).opacity(0.08) : .white.opacity(0.14)
    }

    public var glassEdge: Color {
        self == .done ? Color(hex: PaletteHex.doneInk).opacity(0.14) : .white.opacity(0.18)
    }

    public var glassInk: Color {
        self == .done ? Color(hex: PaletteHex.doneInkDim) : .white.opacity(0.72)
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

    /// 設定画面の色。
    public static let well = Color(hex: PaletteHex.well)
    public static let accent = Color(hex: PaletteHex.accent)
}
