import AppKit
import CoreGraphics
import Foundation

// 文字盤のコンプリケーション（accessoryCircular）の案を並べて描く。
//
// 実機に置く操作は本人にしか頼めないので、**実寸で1枚に並べて見比べる。**
// 46mm の accessoryCircular はおよそ 42pt（＝ 84px @2x）。そのままの大きさと、
// 3倍に拡大したものを並べる。地は文字盤を想わせる暗い灰色。

let ACC: CGFloat = 84          // 実寸（@2x）
let BIG: CGFloat = 252         // 見比べ用

func color(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF)/255, green: CGFloat((hex >> 8) & 0xFF)/255,
            blue: CGFloat(hex & 0xFF)/255, alpha: a)
}
func newContext(_ w: Int, _ h: Int) -> CGContext {
    guard let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { fatalError("context") }
    return c
}
func savePNG(_ image: CGImage, _ path: String) {
    let rep = NSBitmapImageRep(cgImage: image)
    guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("png") }
    try! data.write(to: URL(fileURLWithPath: path))
}

// アプリと同じ配色
let GROUND: UInt32 = 0x0B2E30
let LIQUID_TOP: UInt32 = 0x22B8AE
let LIQUID_BOTTOM: UInt32 = 0x0F8A82
let INK: UInt32 = 0xFFFFFF

func roundedFont(_ size: CGFloat, _ weight: NSFont.Weight) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: weight)
    guard let d = base.fontDescriptor.withDesign(.rounded), let f = NSFont(descriptor: d, size: size) else { return base }
    return f
}

/// 中央ぞろえで文字を描く。`dy` は中心からのずらし（上が正）。
func drawText(_ ctx: CGContext, _ text: String, size: CGFloat, weight: NSFont.Weight,
              color c: CGColor, center: CGPoint, dy: CGFloat = 0) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: roundedFont(size, weight),
        .foregroundColor: NSColor(cgColor: c)!,
        .kern: -size * 0.03,
    ]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))
    let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
    ctx.textPosition = CGPoint(x: center.x - bounds.width / 2 - bounds.origin.x,
                               y: center.y - bounds.height / 2 - bounds.origin.y + dy)
    CTLineDraw(line, ctx)
}

func gradient(_ a: UInt32, _ b: UInt32) -> CGGradient {
    CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
               colors: [color(a), color(b)] as CFArray, locations: [0, 1])!
}

/// 円に切り抜いて地を塗る
func fillGround(_ ctx: CGContext, _ s: CGFloat, _ hex: UInt32 = GROUND) {
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: 0, y: 0, width: s, height: s)); ctx.clip()
    ctx.setFillColor(color(hex)); ctx.fill(CGRect(x: 0, y: 0, width: s, height: s))
    ctx.restoreGState()
}

/// 下から `level` ぶんの水
func fillWater(_ ctx: CGContext, _ s: CGFloat, level: CGFloat, line: Bool = true) {
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: 0, y: 0, width: s, height: s)); ctx.clip()
    let h = s * level
    ctx.clip(to: CGRect(x: 0, y: 0, width: s, height: h))
    ctx.drawLinearGradient(gradient(LIQUID_TOP, LIQUID_BOTTOM),
                           start: CGPoint(x: 0, y: h), end: CGPoint(x: 0, y: 0), options: [])
    if line {
        ctx.setFillColor(color(0xFFFFFF, 0.6))
        ctx.fill(CGRect(x: 0, y: h - s * 0.02, width: s, height: s * 0.02))
    }
    ctx.restoreGState()
}

func strokeRing(_ ctx: CGContext, _ s: CGFloat, width: CGFloat, _ c: CGColor, inset: CGFloat = 0) {
    ctx.setStrokeColor(c)
    ctx.setLineWidth(width)
    let r = CGRect(x: width/2 + inset, y: width/2 + inset, width: s - width - inset*2, height: s - width - inset*2)
    ctx.strokeEllipse(in: r)
}

// ───────── 枠の太さを見比べる ─────────
//
// accessoryCircular は直径 42pt ほど。線幅を pt で決めて、実寸（@2x = 84px）で見る。

let NUMBER = "90"

/// E 案。`ringPt` は 42pt の円に対する線幅（pt）。
func drawE(_ ctx: CGContext, _ s: CGFloat, ringPt: CGFloat) {
    fillGround(ctx, s)
    let w = s * ringPt / 42
    strokeRing(ctx, s, width: w, color(LIQUID_TOP, 0.8))
    // ストップウォッチの絵（円＋つまみ＋針）
    let cx = s/2, cy = s * 0.63, r = s * 0.12
    ctx.setStrokeColor(color(LIQUID_TOP)); ctx.setLineWidth(s * 0.035); ctx.setLineCap(.round)
    ctx.strokeEllipse(in: CGRect(x: cx - r, y: cy - r, width: r*2, height: r*2))
    ctx.beginPath(); ctx.move(to: CGPoint(x: cx, y: cy + r)); ctx.addLine(to: CGPoint(x: cx, y: cy + r + s*0.05)); ctx.strokePath()
    ctx.beginPath(); ctx.move(to: CGPoint(x: cx, y: cy)); ctx.addLine(to: CGPoint(x: cx + r*0.6, y: cy + r*0.5)); ctx.strokePath()
    drawText(ctx, NUMBER, size: s * 0.36, weight: .heavy, color: color(INK), center: CGPoint(x: s/2, y: s * 0.29))
}

let widths: [CGFloat] = [1.5, 3, 4.5, 6]

func image(_ s: CGFloat, ringPt: CGFloat) -> CGImage {
    let ctx = newContext(Int(s), Int(s))
    drawE(ctx, s, ringPt: ringPt)
    return ctx.makeImage()!
}

let cell: CGFloat = BIG + 40
let sheetW = cell * CGFloat(widths.count) + 40
let sheetH = cell + 60
let sheet = newContext(Int(sheetW), Int(sheetH))
sheet.setFillColor(color(0x101010)); sheet.fill(CGRect(x: 0, y: 0, width: sheetW, height: sheetH))

for (i, w) in widths.enumerated() {
    let x = 20 + CGFloat(i) * cell
    sheet.draw(image(BIG, ringPt: w), in: CGRect(x: x + (cell - BIG)/2, y: 60, width: BIG, height: BIG))
    sheet.draw(image(ACC, ringPt: w), in: CGRect(x: x + cell - 96, y: 60 + BIG - ACC, width: ACC, height: ACC))
    drawText(sheet, "線幅 \(w == 1.5 ? "1.5（前）" : "\(Int(w))")pt", size: 24, weight: .semibold,
             color: color(0xEDE7DC), center: CGPoint(x: x + cell/2, y: 30))
}
savePNG(sheet.makeImage()!, "complication-ring.png")
print("書き出しました: complication-ring.png")
