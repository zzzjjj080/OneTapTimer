// 番号付きの見本表を描く（`Tools-MakeCatalog.sh` から使う）。
//
// **1行に1種類。** その種類だけを変えて、ほかは既定のまま並べる。
// 本人はこの絵を見て「W3 を消す」と番号で指す。
//
// 1枚目は**文字盤（コンプリケーション）**。文字盤にいつも出ているので、ここがいちばん目に入る。
// 2枚目はアプリの画面。
import AppKit
import SwiftUI

let now = Date(timeIntervalSince1970: 1_000_000)
/// 走っている見本（90秒のうち32秒経過＝残り58秒）
let running = TimerEngine(duration: 90, startedAt: now.addingTimeInterval(-32))

// **見本には、その項目だけを描く**（編集画面の選択肢と同じ描き分け。2026-09-27 本人指示）。
// 色なら色だけ、絵なら絵だけ、輪なら輪だけ。ほかの要素まで出ていると、どれを選ぶのか分からない。
enum Art {
    case dial, symbol, ring, swatch, dialNumber   // 文字盤
    case meter, digits, placement, face           // アプリの画面
}

let dialGround = Color(hex: 0x0B2E30)
let side: CGFloat = 58

struct Cell: View {
    let code: String
    let label: String
    let design: FaceDesign
    let art: Art

    private var accent: Color { Color(hex: design.theme.liquidTop) }

    var body: some View {
        VStack(spacing: 3) {
            picture
            Text(code).font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text(label).font(.system(size: 9)).foregroundStyle(.gray).lineLimit(1)
        }
        .frame(width: 70)
    }

    @ViewBuilder
    private var picture: some View {
        switch art {
        case .dial:
            circle { DialFace(design: design, duration: 90, diameter: side) }
        case .symbol:
            circle {
                Image(systemName: design.dialMark.symbol)
                    .font(.system(size: side * 0.42, weight: .semibold))
                    .foregroundStyle(accent)
            }
        case .ring:
            circle { DialRingArt(ring: design.dialRing, color: accent, diameter: side) }
        case .swatch:
            Circle()
                .fill(LinearGradient(colors: [Color(hex: design.theme.liquidTop),
                                              Color(hex: design.theme.liquidBottom)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: side, height: side)
        case .dialNumber:
            circle {
                var d = design
                let _ = { d.dialContent = .numberOnly; d.dialRing = .none; d.dialTint = .colored }()
                DialFace(design: d, duration: 90, diameter: side)
            }
        case .meter:
            screen { DrainFace(engine: running, now: now, design: design, metrics: .sample,
                               showsDigits: false) }
        case .digits, .placement:
            screen { DrainFace(engine: running, now: now, design: design, metrics: .sample,
                               showsMeter: false) }
        case .face:
            screen { DrainFace(engine: running, now: now, design: design, metrics: .sample) }
        }
    }

    private func circle(@ViewBuilder _ content: () -> some View) -> some View {
        ZStack { Circle().fill(dialGround); content() }
            .frame(width: side, height: side)
    }

    private func screen(@ViewBuilder _ content: () -> some View) -> some View {
        content()
            .frame(width: side, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
            }
    }
}

func row<T: NumberedChoice>(_ title: String, _ t: T.Type, art: Art,
                            _ apply: @escaping (inout FaceDesign, T) -> Void) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(70), spacing: 6), count: 10),
                  alignment: .leading, spacing: 10) {
            ForEach(T.allCases) { c in
                let d: FaceDesign = { var x = FaceDesign.standard; apply(&x, c); return x }()
                Cell(code: c.code, label: c.label, design: d, art: art)
            }
        }
    }
}

struct Sheet1: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("ワンタップタイマー 見た目の見本（1/2）文字盤のコンプリケーション")
                .font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
            row("C 色（文字盤にもアプリにも効く）", FaceColor.self, art: .swatch) { $0.color = $1 }
            row("W 中身", DialContent.self, art: .dial) { $0.dialContent = $1 }
            row("I 絵", DialMark.self, art: .symbol) { $0.dialMark = $1 }
            row("R 輪", DialRing.self, art: .ring) { $0.dialRing = $1 }
            row("V 色の付け方", DialTint.self, art: .dial) { $0.dialTint = $1 }
            row("U 大きさ", DialSize.self, art: .dialNumber) { $0.dialSize = $1 }
            row("J 書体", DialTypeface.self, art: .dialNumber) { $0.dialTypeface = $1 }
            Text("※ ほかの項目は既定のまま。組み合わせは 1 行で表せる（例 \(FaceDesign.standard.text)）")
                .font(.system(size: 10)).foregroundStyle(.gray)
        }
        .padding(20)
        .background(Color(white: 0.06))
    }
}

struct Sheet2: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("ワンタップタイマー 見た目の見本（2/2）アプリの画面")
                .font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
            row("Y 減り方（形だけ）", FaceStyle.self, art: .meter) { $0.style = $1 }
            row("N 数字", FaceDigits.self, art: .digits) { $0.digits = $1 }
            row("S 大きさ", FaceSize.self, art: .digits) { $0.size = $1 }
            row("T 書体", FaceTypeface.self, art: .digits) { $0.typeface = $1 }
            row("F 文字の太さ", FaceWeight.self, art: .digits) { $0.weight = $1 }
            row("O 縁取り（水の上でしか違わない）", FaceOutline.self, art: .face) { $0.outline = $1 }
            row("P 置き場所", FacePlace.self, art: .placement) { $0.place = $1 }
        }
        .padding(20)
        .background(Color(white: 0.06))
    }
}

@MainActor
func render(_ view: some View, to path: String) {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 2
    guard let image = renderer.nsImage,
          let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("描けなかった"); exit(1)
    }
    try? png.write(to: URL(fileURLWithPath: path))
    print("書いた:", path)
}

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "catalog.png"
let part = CommandLine.arguments.count > 2 ? Int(CommandLine.arguments[2]) ?? 1 : 1
MainActor.assumeIsolated {
    render(part == 1 ? AnyView(Sheet1()) : AnyView(Sheet2()), to: out)
}
