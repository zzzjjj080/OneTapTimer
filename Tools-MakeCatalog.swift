// 番号付きの見本表を描く（`Tools-MakeCatalog.sh` から使う）。
//
// **1行に1種類。** その種類だけを変えて、ほかは既定のまま並べる。
// 本人はこの絵を見て「Y3 を消す」と番号で指す。
import AppKit
import SwiftUI

let now = Date(timeIntervalSince1970: 1_000_000)
/// 走っている見本（90秒のうち32秒経過＝残り58秒）
let running = TimerEngine(duration: 90, startedAt: now.addingTimeInterval(-32))
/// 終わりが近い見本（30秒のうち残り7秒）。**20秒以下のタイマーには「終わりが近い」が無い**
/// （`finalStretchNeeds`）。90秒だと水がほぼ無くなって色の違いが見えないので、30秒にする
let ending = TimerEngine(duration: 30, startedAt: now.addingTimeInterval(-23))
/// 終わった見本。**`advance` を通さないと「終わった」にならない**（時刻を渡しただけでは走ったままになる）
let finished: TimerEngine = {
    var e = TimerEngine(duration: 90, startedAt: now.addingTimeInterval(-91))
    _ = e.advance(to: now)
    return e
}()

struct Cell: View {
    let code: String
    let label: String
    let design: FaceDesign
    var engine: TimerEngine = running

    var body: some View {
        VStack(spacing: 3) {
            DrainFace(engine: engine, now: now, design: design, metrics: .sample)
                .frame(width: 58, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            Text(code).font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text(label).font(.system(size: 9)).foregroundStyle(.gray).lineLimit(1)
        }
        .frame(width: 66)
    }
}

func row<T: NumberedChoice>(_ title: String, _ t: T.Type, engine: TimerEngine = running,
                            _ apply: @escaping (inout FaceDesign, T) -> Void) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(66), spacing: 6), count: 10),
                  alignment: .leading, spacing: 10) {
            ForEach(T.allCases) { c in
                let d: FaceDesign = { var x = FaceDesign.standard; apply(&x, c); return x }()
                Cell(code: c.code, label: c.label, design: d, engine: engine)
            }
        }
    }
}

struct Sheet1: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("ワンタップタイマー 見た目の見本（1/2）形と色")
                .font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
            row("Y 減り方", FaceStyle.self) { $0.style = $1 }
            row("C 色", FaceColor.self) { $0.color = $1 }
            row("G 塗り方", FaceFill.self) { $0.fill = $1 }
            row("D 向き", FaceDirection.self) { $0.direction = $1 }
            row("B 地の色", FaceGround.self) { $0.ground = $1 }
            row("M 目盛り", FaceTicks.self) { $0.ticks = $1 }
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
            Text("ワンタップタイマー 見た目の見本（2/2）数字と仕上げ")
                .font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
            row("N 数字", FaceDigits.self) { $0.digits = $1 }
            row("S 大きさ", FaceSize.self) { $0.size = $1 }
            row("T 書体", FaceTypeface.self) { $0.typeface = $1 }
            row("F 文字の太さ", FaceWeight.self) { $0.weight = $1 }
            row("K 文字の色", FaceInk.self) { $0.ink = $1 }
            row("O 縁取り", FaceOutline.self) { $0.outline = $1 }
            row("P 置き場所", FacePlace.self) { $0.place = $1 }
            row("L 終わりが近いとき（残り7秒の見本）", FaceLast.self, engine: ending) { $0.last = $1 }
            row("E 終わった画面（終わった見本）", FaceDone.self, engine: finished) { $0.done = $1 }
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
