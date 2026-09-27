import SwiftUI
import WidgetKit
import OneTapTimerCore
import OneTapTimerUI

/// 文字盤に置いて、一発でアプリを開くためのコンプリケーション。
///
/// **これがこのアプリの「ワンタップ」。** 押すとアプリが開き、開いた瞬間に走り出す。
/// 出すのは**設定してある秒数**（`90`）だけ。
///
/// **残り時間は出さない。** アプリから出た時点でタイマーは止まるので、
/// 文字盤を見ているときに「走っている」ことはあり得ない。
/// 一度カウントダウンを出す作りにしたら、クラウンで抜けた直後に
/// **古い残り時間が一瞬だけ残って見えた**（WidgetKit の描き直しが追いつかない）。
///
/// **見た目は iPhone アプリで決める**（1.3 から）。丸の中身は `OneTapTimerUI` の `DialFace`。
/// アプリ側の見本と同じコードで描くので、**選んだとおりのものが文字盤に出る。**
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
    /// iPhone で決めた見た目
    let design: FaceDesign
}

struct LaunchProvider: TimelineProvider {
    private func entry(_ date: Date) -> LaunchEntry {
        let d = SharedStore.defaults
        let saved = d.integer(forKey: SharedStore.durationKey)
        return LaunchEntry(date: date,
                           duration: saved == 0 ? DurationRule.standard : saved,
                           design: SharedStore.design(d))
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

    private var fullColor: Bool { mode == .fullColor }
    private var accent: Color {
        fullColor ? Color(hex: entry.design.theme.liquidTop) : .white
    }

    var body: some View {
        content
            // **watchOS 10 以降はこれが必須。** 無いと丸にビックリマークになる（引き継ぎ書 4-86）
            .containerBackground(for: .widget) { background }
    }

    @ViewBuilder
    private var background: some View {
        if fullColor {
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
                Image(systemName: entry.design.dialMark.symbol)
                number
                Text("秒")
            }
        case .accessoryRectangular:
            HStack(spacing: 8) {
                DialFace(design: entry.design, duration: entry.duration,
                         diameter: 34, fullColor: fullColor)
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
            // 角では輪を描く余地が無いので、絵だけを置いて秒数は縁のラベルへ
            Image(systemName: entry.design.dialMark.symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(accent)
                .widgetAccentable()
                .padding(2)
                .widgetLabel { number.monospacedDigit() }
        default:
            // 丸い枠。**中身は iPhone で決めた見た目のまま**
            DialFace(design: entry.design, duration: entry.duration,
                     diameter: 46, fullColor: fullColor)
        }
    }
}

enum Palette {
    /// アプリの地より少し明るい濃いティール。真っ黒だと文字盤で消える
    static let ground = Color(red: 0x0B/255, green: 0x2E/255, blue: 0x30/255)
}
