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

    static func read(now: Date) -> (duration: Int, endAt: Date?) {
        let d = UserDefaults(suiteName: groupID)
        let saved = d?.integer(forKey: "duration") ?? 0
        let duration = saved == 0 ? standard : saved
        guard let data = d?.data(forKey: "engine"),
              let e = try? JSONDecoder().decode(Engine.self, from: data),
              e.finishedAt == nil, e.endAt > now else { return (duration, nil) }
        return (duration, e.endAt)
    }
}

struct LaunchProvider: TimelineProvider {
    func placeholder(in context: Context) -> LaunchEntry {
        LaunchEntry(date: .now, duration: SharedState.standard, endAt: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (LaunchEntry) -> Void) {
        let s = SharedState.read(now: .now)
        completion(LaunchEntry(date: .now, duration: s.duration, endAt: s.endAt))
    }

    /// 走っていれば「いま」と「終わる時刻」の2枚。終わる時刻で秒数の表示に戻る。
    /// それ以外は1枚で、作り直させない（アプリが書き換えたときに reload させる）。
    func getTimeline(in context: Context, completion: @escaping (Timeline<LaunchEntry>) -> Void) {
        let now = Date()
        let s = SharedState.read(now: now)
        var entries = [LaunchEntry(date: now, duration: s.duration, endAt: s.endAt)]
        if let end = s.endAt {
            entries.append(LaunchEntry(date: end, duration: s.duration, endAt: nil))
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
                LevelGlyph(number: nil).frame(width: 32, height: 32)
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
            LevelGlyph(number: nil)
                .widgetLabel { number.monospacedDigit() }
        default:
            // 丸い枠：水の絵の上に秒数
            LevelGlyph(number: AnyView(number)).padding(1)
        }
    }
}

enum Palette {
    /// アプリの地より少し明るい濃いティール。真っ黒だと文字盤で消える
    static let ground = Color(red: 0x0B/255, green: 0x2E/255, blue: 0x30/255)
    static let liquid = Color(red: 0x22/255, green: 0xB8/255, blue: 0xAE/255)
    static let rim = Color.white.opacity(0.55)
}

/// 下に水が溜まった丸。アプリの画面そのもの。
///
/// **`GeometryReader` を使わない。** コンプリケーションの枠は極端に小さく、
/// 測らせると 0 や NaN が返ってきて描画ごと落ちることがある。`Shape` は矩形をそのまま受け取る。
struct LevelGlyph: View {
    /// 真ん中に載せる数字。`nil` なら絵だけ
    let number: AnyView?
    @Environment(\.widgetRenderingMode) private var mode

    var body: some View {
        ZStack {
            if mode == .fullColor {
                LevelShape(level: 0.42).fill(Palette.liquid)
                RingShape().stroke(Palette.rim, lineWidth: 2)
            } else {
                // 単色に着色される文字盤では、水を強調色に。輪は薄く
                LevelShape(level: 0.42).fill(.white.opacity(0.35)).widgetAccentable()
                RingShape().stroke(.white.opacity(0.5), lineWidth: 2)
            }
            if let number {
                number
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 1.5, y: 1)
                    .padding(.horizontal, 5)
            }
        }
    }
}

private struct RingShape: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height) - 2
        guard side > 1 else { return Path() }
        return Path(ellipseIn: CGRect(x: rect.midX - side / 2, y: rect.midY - side / 2, width: side, height: side))
    }
}

/// 円の下 `level` ぶんだけ。
private struct LevelShape: Shape {
    let level: Double
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height) - 2
        guard side > 1 else { return Path() }
        let circle = CGRect(x: rect.midX - side / 2, y: rect.midY - side / 2, width: side, height: side)
        let water = CGRect(x: circle.minX, y: circle.maxY - circle.height * level,
                           width: circle.width, height: circle.height * level)
        return Path(ellipseIn: circle).intersection(Path(water))
    }
}
