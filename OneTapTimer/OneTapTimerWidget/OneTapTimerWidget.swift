import SwiftUI
import WidgetKit

/// 文字盤に置いて、一発でアプリを開くためのコンプリケーション。
///
/// **これがこのアプリの「ワンタップ」。** 押すとアプリが開き、開いた瞬間に走り出す。
/// **設定してある秒数**（`90`）を出す。走っている間は残りのカウントダウンに変わり、
/// 終わる時刻でひとりでに `90` へ戻る。状態は App Group の UserDefaults で受け取る。
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
    /// 走っていれば終わる時刻
    let endAt: Date?
    /// 水の色（アプリの色の組と同じ）
    let liquid: Color
    var isRunning: Bool { endAt.map { $0 > date } ?? false }
}

/// アプリが App Group に書いている状態。**キーと形は `OneTapTimerUI` の `SharedStore` / `TimerEngine` と同じ。**
/// 拡張はパッケージを読み込まないので、自前で同じ形を読む。
enum SharedState {
    static let groupID = "group.com.zzzjjj080.OneTapTimer"
    static let standard = 90

    private struct Engine: Decodable {
        let duration: Int
        let endAt: Date
        let finishedAt: Date?
    }

    /// 色の組の「水の上端」。アプリの `ThemeHex.all` と同じ並び（1〜10）
    static let liquids: [UInt32] = [0x22B8AE, 0x3B9DF0, 0x6C7BEA, 0xA56BE8, 0xF06AA8,
                                    0xF0605A, 0xF5923A, 0xE6C02A, 0x4FC46A, 0xA9B0B8]

    static func read(now: Date) -> (duration: Int, endAt: Date?, liquid: Color) {
        let d = UserDefaults(suiteName: groupID)
        let saved = d?.integer(forKey: "duration") ?? 0
        let duration = saved == 0 ? standard : saved
        let t = d?.integer(forKey: "theme") ?? 0
        let hex = (1...liquids.count).contains(t) ? liquids[t - 1] : liquids[0]
        let liquid = Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
        guard let data = d?.data(forKey: "engine"),
              let e = try? JSONDecoder().decode(Engine.self, from: data),
              e.finishedAt == nil, e.endAt > now else { return (duration, nil, liquid) }
        return (duration, e.endAt, liquid)
    }
}

struct LaunchProvider: TimelineProvider {
    func placeholder(in context: Context) -> LaunchEntry {
        LaunchEntry(date: .now, duration: SharedState.standard, endAt: nil, liquid: Palette.liquid)
    }

    func getSnapshot(in context: Context, completion: @escaping (LaunchEntry) -> Void) {
        let s = SharedState.read(now: .now)
        completion(LaunchEntry(date: .now, duration: s.duration, endAt: s.endAt, liquid: s.liquid))
    }

    /// 走っていれば「いま」と「終わる時刻」の2枚。終わる時刻で秒数の表示に戻る。
    /// それ以外は1枚で、作り直させない（アプリが書き換えたときに reload させる）。
    func getTimeline(in context: Context, completion: @escaping (Timeline<LaunchEntry>) -> Void) {
        let now = Date()
        let s = SharedState.read(now: now)
        var entries = [LaunchEntry(date: now, duration: s.duration, endAt: s.endAt, liquid: s.liquid)]
        if let end = s.endAt {
            entries.append(LaunchEntry(date: end, duration: s.duration, endAt: nil, liquid: s.liquid))
        }
        completion(Timeline(entries: entries, policy: .never))
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

    /// 走っていれば残り（システムが描く。`1:29` の形）、それ以外は設定してある秒数（`90`）。
    @ViewBuilder
    private var number: some View {
        if let end = entry.endAt, entry.isRunning {
            Text(timerInterval: entry.date...end, pauseTime: nil, countsDown: true, showsHours: false)
        } else {
            Text("\(entry.duration)")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryInline:
            HStack(spacing: 4) {
                Image(systemName: "timer")
                number
                if !entry.isRunning { Text("秒") }
            }
        case .accessoryRectangular:
            HStack(spacing: 8) {
                Mark(liquid: entry.liquid, size: 26).frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 1) {
                    Text("ワンタップタイマー").font(.headline)
                    HStack(spacing: 3) {
                        number.font(.caption.weight(.semibold).monospacedDigit())
                        Text(entry.isRunning ? "のこり" : "秒 · 押すと始まる").font(.caption2).foregroundStyle(.secondary)
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
            Face(liquid: entry.liquid) { AnyView(number) }
        }
    }
}

/// 丸い枠の中身。**上にマーク、下に数字。**
///
/// **`GeometryReader` を使わない。** コンプリケーションの枠は極端に小さく、
/// 測らせると 0 や NaN が返ってきて描画ごと落ちることがある。寸法は決め打ちにする。
struct Face: View {
    let liquid: Color
    let number: () -> AnyView
    @Environment(\.widgetRenderingMode) private var mode

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(mode == .fullColor ? liquid.opacity(0.7) : .white.opacity(0.5),
                              lineWidth: 1.5)

            VStack(spacing: -1) {
                Mark(liquid: liquid, size: 13)
                number()
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 3)
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

