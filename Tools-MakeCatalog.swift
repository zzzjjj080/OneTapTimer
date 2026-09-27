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

/// 文字盤の丸ひとつ
struct DialCell: View {
    let code: String
    let label: String
    let design: FaceDesign

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle().fill(Color(hex: 0x0B2E30))
                DialFace(design: design, duration: 90, diameter: 58)
            }
            .frame(width: 58, height: 58)
            Text(code).font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text(label).font(.system(size: 9)).foregroundStyle(.gray).lineLimit(1)
        }
        .frame(width: 70)
    }
}

/// アプリの画面ひとつ
struct FaceCell: View {
    let code: String
    let label: String
    let design: FaceDesign

    var body: some View {
        VStack(spacing: 3) {
            DrainFace(engine: running, now: now, design: design, metrics: .sample)
                .frame(width: 58, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            Text(code).font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text(label).font(.system(size: 9)).foregroundStyle(.gray).lineLimit(1)
        }
        .frame(width: 70)
    }
}

func row<T: NumberedChoice>(_ title: String, _ t: T.Type, dial: Bool,
                            _ apply: @escaping (inout FaceDesign, T) -> Void) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(70), spacing: 6), count: 10),
                  alignment: .leading, spacing: 10) {
            ForEach(T.allCases) { c in
                let d: FaceDesign = { var x = FaceDesign.standard; apply(&x, c); return x }()
                if dial {
                    DialCell(code: c.code, label: c.label, design: d)
                } else {
                    FaceCell(code: c.code, label: c.label, design: d)
                }
            }
        }
    }
}

struct Sheet1: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("ワンタップタイマー 見た目の見本（1/2）文字盤のコンプリケーション")
                .font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
            row("W 中身", DialContent.self, dial: true) { $0.dialContent = $1 }
            row("I 絵", DialMark.self, dial: true) { $0.dialMark = $1 }
            row("R 輪", DialRing.self, dial: true) { $0.dialRing = $1 }
            row("V 色の付け方", DialTint.self, dial: true) { $0.dialTint = $1 }
            row("U 大きさ", DialSize.self, dial: true) { $0.dialSize = $1 }
            row("J 書体", DialTypeface.self, dial: true) { $0.dialTypeface = $1 }
            row("C 色（文字盤にも効く）", FaceColor.self, dial: true) { $0.color = $1 }
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
            row("Y 減り方", FaceStyle.self, dial: false) { $0.style = $1 }
            row("C 色", FaceColor.self, dial: false) { $0.color = $1 }
            row("N 数字", FaceDigits.self, dial: false) { $0.digits = $1 }
            row("S 大きさ", FaceSize.self, dial: false) { $0.size = $1 }
            row("T 書体", FaceTypeface.self, dial: false) { $0.typeface = $1 }
            row("F 文字の太さ", FaceWeight.self, dial: false) { $0.weight = $1 }
            row("O 縁取り", FaceOutline.self, dial: false) { $0.outline = $1 }
            row("P 置き場所", FacePlace.self, dial: false) { $0.place = $1 }
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
