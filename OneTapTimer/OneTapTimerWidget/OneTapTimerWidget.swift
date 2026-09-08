import SwiftUI
import WidgetKit

/// 文字盤に置いて、一発でアプリを開くためのコンプリケーション。
///
/// **これがこのアプリの「ワンタップ」。** 押すとアプリが開き、開いた瞬間に走り出す。
/// 残り時間は出していない（アプリと拡張で状態を共有する仕掛けが増える）。
@main
struct OneTapTimerWidgetBundle: WidgetBundle {
    var body: some Widget { LaunchComplication() }
}

struct LaunchComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "OneTapTimerLaunch", provider: LaunchProvider()) { _ in
            ComplicationView()
        }
        .configurationDisplayName("ワンタップタイマー")
        .description("タップするとタイマーが始まります。")
        .supportedFamilies([.accessoryCircular, .accessoryCorner,
                            .accessoryInline, .accessoryRectangular])
    }
}

struct LaunchEntry: TimelineEntry { let date: Date }

struct LaunchProvider: TimelineProvider {
    func placeholder(in context: Context) -> LaunchEntry { LaunchEntry(date: .now) }

    func getSnapshot(in context: Context, completion: @escaping (LaunchEntry) -> Void) {
        completion(LaunchEntry(date: .now))
    }

    /// 中身が時刻で変わらないので、作り直させない。
    func getTimeline(in context: Context, completion: @escaping (Timeline<LaunchEntry>) -> Void) {
        completion(Timeline(entries: [LaunchEntry(date: .now)], policy: .never))
    }
}

struct ComplicationView: View {
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

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryInline:
            Label("ワンタップタイマー", systemImage: "timer")
        case .accessoryRectangular:
            HStack(spacing: 8) {
                LevelGlyph().frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 1) {
                    Text("ワンタップタイマー").font(.headline)
                    Text("押すと始まる").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        case .accessoryCorner:
            LevelGlyph().widgetLabel("ワンタップ")
        default:
            LevelGlyph().padding(2)
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
    @Environment(\.widgetRenderingMode) private var mode

    var body: some View {
        ZStack {
            if mode == .fullColor {
                LevelShape(level: 0.58).fill(Palette.liquid)
                RingShape().stroke(Palette.rim, lineWidth: 2)
            } else {
                // 単色に着色される文字盤では、水を強調色に。輪は薄く
                LevelShape(level: 0.58).fill(.white).widgetAccentable()
                RingShape().stroke(.white.opacity(0.5), lineWidth: 2)
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
