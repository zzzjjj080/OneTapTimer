import SwiftUI
import WidgetKit

/// 文字盤に置いて、一発でアプリを開くためのコンプリケーション。
///
/// **これがこのアプリの「ワンタップ」。** 押すとアプリが開き、開いた瞬間に走り出す。
/// 出すのは**設定してある秒数**（`90`）だけ。
///
/// **残り時間は出さない。** アプリから出た時点でタイマーは止まるので、
/// 文字盤を見ているときに「走っている」ことはあり得ない。
/// 一度カウントダウンを出す作りにしたら、クラウンで抜けた直後に
/// **古い残り時間が一瞬だけ残って見えた**（WidgetKit の描き直しが追いつかない）。
@main
struct OneTapTimerWidgetBundle: WidgetBundle {
    var body: some Widget { LaunchComplication() }
}

struct LaunchComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "OneTapTimerLaunch", provider: LaunchProvider()) { entry in
            ComplicationView(entry: entry)
        }
        .configurationDisplayName("ワンタップタイマー")
        .description("タップするとタイマーが始まります。")
        .supportedFamilies([.accessoryCircular, .accessoryCorner,
                            .accessoryInline, .accessoryRectangular])
    }
}

struct LaunchEntry: TimelineEntry {
    let date: Date
    /// 設定してある秒数
    let duration: Int
    /// 水の色（アプリの色の組と同じ）
    let liquid: Color
}

/// アプリが App Group に書いている設定。**キーは `OneTapTimerUI` の `SharedStore` と同じ。**
/// 拡張はパッケージを読み込まないので、自前で同じキーを読む。
enum SharedState {
    static let groupID = "group.com.zzzjjj080.OneTapTimer"
    static let standard = 90

    /// 色の組の「水の上端」。アプリの `ThemeHex.all` と同じ並び（1〜10）
    static let liquids: [UInt32] = [0x22B8AE, 0x3B9DF0, 0x6C7BEA, 0xA56BE8, 0xF06AA8,
                                    0xF0605A, 0xF5923A, 0xE6C02A, 0x4FC46A, 0xA9B0B8]

    static func read() -> (duration: Int, liquid: Color) {
        let d = UserDefaults(suiteName: groupID)
        let saved = d?.integer(forKey: "duration") ?? 0
        let t = d?.integer(forKey: "theme") ?? 0
        let hex = (1...liquids.count).contains(t) ? liquids[t - 1] : liquids[0]
        return (saved == 0 ? standard : saved,
                Color(red: Double((hex >> 16) & 0xFF) / 255,
                      green: Double((hex >> 8) & 0xFF) / 255,
                      blue: Double(hex & 0xFF) / 255))
    }
}

struct LaunchProvider: TimelineProvider {
    private func entry(_ date: Date) -> LaunchEntry {
        let s = SharedState.read()
        return LaunchEntry(date: date, duration: s.duration, liquid: s.liquid)
    }

    func placeholder(in context: Context) -> LaunchEntry { entry(.now) }

    func getSnapshot(in context: Context, completion: @escaping (LaunchEntry) -> Void) {
        completion(entry(.now))
    }

    /// 時刻では変わらないので、作り直させない。
    /// 設定が変わったときだけ、アプリ側から `WidgetCenter` に描き直させる。
    func getTimeline(in context: Context, completion: @escaping (Timeline<LaunchEntry>) -> Void) {
        completion(Timeline(entries: [entry(.now)], policy: .never))
    }
}

struct ComplicationView: View {
    let entry: LaunchEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var mode

    var body: some View {
        content
            // **watchOS 10 以降はこれが必須。** 無いと丸にビックリマークになる（引き継ぎ書 4-86）
            .containerBackground(for: .widget) { background }
    }

    @ViewBuilder
    private var background: some View {
        if mode == .fullColor {
            Palette.ground
        } else {
            AccessoryWidgetBackground()
        }
    }

    private var number: Text { Text("\(entry.duration)") }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryInline:
            HStack(spacing: 4) {
                Image(systemName: "timer")
                number
                Text("秒")
            }
        case .accessoryRectangular:
            HStack(spacing: 8) {
                Mark(liquid: entry.liquid, size: 26).frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 1) {
                    Text("ワンタップタイマー").font(.headline)
                    HStack(spacing: 3) {
                        number.font(.caption.weight(.semibold).monospacedDigit())
                        Text("秒 · 押すと始まる").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
        case .accessoryCorner:
            Mark(liquid: entry.liquid, size: 22)
                .padding(2)
                .widgetLabel { number.monospacedDigit() }
        default:
            // 丸い枠：上にストップウォッチ、下に秒数
            Face(liquid: entry.liquid, number: number)
        }
    }
}

/// 丸い枠の中身。**上にマーク、下に数字。**
///
/// **`GeometryReader` を使わない。** コンプリケーションの枠は極端に小さく、
/// 測らせると 0 や NaN が返ってきて描画ごと落ちることがある。寸法は決め打ちにする。
struct Face: View {
    let liquid: Color
    let number: Text
    @Environment(\.widgetRenderingMode) private var mode

    var body: some View {
        ZStack {
            // **細いと文字盤に埋もれる。** 実寸（直径42ptほど）で見て3ptにした
            Circle()
                .strokeBorder(mode == .fullColor ? liquid.opacity(0.8) : .white.opacity(0.55),
                              lineWidth: 3)

            VStack(spacing: -1) {
                Mark(liquid: liquid, size: 12)
                number
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 5)
        }
    }
}

/// ストップウォッチのマーク。単色に着色される文字盤では、ここだけ色が乗るようにする。
struct Mark: View {
    let liquid: Color
    let size: CGFloat
    @Environment(\.widgetRenderingMode) private var mode

    var body: some View {
        Image(systemName: "timer")
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(mode == .fullColor ? liquid : .white)
            .widgetAccentable()
    }
}

enum Palette {
    /// アプリの地より少し明るい濃いティール。真っ黒だと文字盤で消える
    static let ground = Color(red: 0x0B/255, green: 0x2E/255, blue: 0x30/255)
    static let liquid = Color(red: 0x22/255, green: 0xB8/255, blue: 0xAE/255)
    static let rim = Color.white.opacity(0.55)
}

