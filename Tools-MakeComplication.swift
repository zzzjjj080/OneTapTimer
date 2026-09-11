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

// ───────── 案 ─────────

let NUMBER = "90"

/// A 現行：水位 ＋ 細い輪 ＋ 数字
func drawA(_ ctx: CGContext, _ s: CGFloat) {
    fillGround(ctx, s)
    fillWater(ctx, s, level: 0.42)
    strokeRing(ctx, s, width: s * 0.024, color(0xFFFFFF, 0.55))
    drawText(ctx, NUMBER, size: s * 0.42, weight: .heavy, color: color(INK), center: CGPoint(x: s/2, y: s/2))
}

/// B 数字だけ：地をアプリの色にして、数字を最大に
func drawB(_ ctx: CGContext, _ s: CGFloat) {
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: 0, y: 0, width: s, height: s)); ctx.clip()
    ctx.drawLinearGradient(gradient(LIQUID_TOP, LIQUID_BOTTOM),
                           start: CGPoint(x: 0, y: s), end: CGPoint(x: 0, y: 0), options: [])
    ctx.restoreGState()
    drawText(ctx, NUMBER, size: s * 0.62, weight: .heavy, color: color(0x06222A), center: CGPoint(x: s/2, y: s/2))
}

/// C リング ＋ 数字：太い輪をアプリの色に。中は暗いまま
func drawC(_ ctx: CGContext, _ s: CGFloat) {
    fillGround(ctx, s)
    strokeRing(ctx, s, width: s * 0.11, color(LIQUID_TOP))
    drawText(ctx, NUMBER, size: s * 0.46, weight: .heavy, color: color(INK), center: CGPoint(x: s/2, y: s/2))
}

/// D 数字が主役：水位は下3割だけ、数字を大きく重ねる
func drawD(_ ctx: CGContext, _ s: CGFloat) {
    fillGround(ctx, s)
    fillWater(ctx, s, level: 0.3, line: true)
    drawText(ctx, NUMBER, size: s * 0.58, weight: .heavy, color: color(INK), center: CGPoint(x: s/2, y: s/2))
}

/// E マーク ＋ 数字：上にストップウォッチ、下に数字
func drawE(_ ctx: CGContext, _ s: CGFloat) {
    fillGround(ctx, s)
    strokeRing(ctx, s, width: s * 0.024, color(LIQUID_TOP, 0.7))
    // ストップウォッチの絵（円＋つまみ＋針）
    let cx = s/2, cy = s * 0.66, r = s * 0.13
    ctx.setStrokeColor(color(LIQUID_TOP)); ctx.setLineWidth(s * 0.035); ctx.setLineCap(.round)
    ctx.strokeEllipse(in: CGRect(x: cx - r, y: cy - r, width: r*2, height: r*2))
    ctx.beginPath(); ctx.move(to: CGPoint(x: cx, y: cy + r)); ctx.addLine(to: CGPoint(x: cx, y: cy + r + s*0.05)); ctx.strokePath()
    ctx.beginPath(); ctx.move(to: CGPoint(x: cx, y: cy)); ctx.addLine(to: CGPoint(x: cx + r*0.6, y: cy + r*0.5)); ctx.strokePath()
    drawText(ctx, NUMBER, size: s * 0.34, weight: .heavy, color: color(INK), center: CGPoint(x: s/2, y: s * 0.27))
}

/// F 下にゲージ：数字を大きく、下端に短い横棒（残量に見える）
func drawF(_ ctx: CGContext, _ s: CGFloat) {
    fillGround(ctx, s)
    strokeRing(ctx, s, width: s * 0.024, color(0xFFFFFF, 0.28))
    drawText(ctx, NUMBER, size: s * 0.56, weight: .heavy, color: color(INK), center: CGPoint(x: s/2, y: s * 0.56))
    let w = s * 0.44, h = s * 0.075, x = (s - w)/2, y = s * 0.17
    ctx.setFillColor(color(0xFFFFFF, 0.22))
    ctx.addPath(CGPath(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerWidth: h/2, cornerHeight: h/2, transform: nil))
    ctx.fillPath()
    ctx.setFillColor(color(LIQUID_TOP))
    ctx.addPath(CGPath(roundedRect: CGRect(x: x, y: y, width: w * 0.62, height: h), cornerWidth: h/2, cornerHeight: h/2, transform: nil))
    ctx.fillPath()
}

let designs: [(String, (CGContext, CGFloat) -> Void)] = [
    ("A 現行 水位＋輪", drawA),
    ("B 数字だけ", drawB),
    ("C 太いリング", drawC),
    ("D 数字主役＋水位", drawD),
    ("E マーク＋数字", drawE),
    ("F 数字＋ゲージ", drawF),
]

func image(_ draw: (CGContext, CGFloat) -> Void, _ s: CGFloat) -> CGImage {
    let ctx = newContext(Int(s), Int(s))
    draw(ctx, s)
    return ctx.makeImage()!
}

// ───────── 並べる ─────────
let cols = 3, rows = 2
let cell: CGFloat = BIG + 60
let sheetW = cell * CGFloat(cols) + 40
let sheetH = cell * CGFloat(rows) + 60
let sheet = newContext(Int(sheetW), Int(sheetH))
sheet.setFillColor(color(0x101010)); sheet.fill(CGRect(x: 0, y: 0, width: sheetW, height: sheetH))

for (i, d) in designs.enumerated() {
    let col = i % cols, row = i / cols
    let x = 20 + CGFloat(col) * cell
    let y = sheetH - 40 - CGFloat(row + 1) * cell + 40
    // 拡大したもの
    sheet.draw(image(d.1, BIG), in: CGRect(x: x + (cell - BIG)/2 - 20, y: y + 44, width: BIG, height: BIG))
    // 実寸
    sheet.draw(image(d.1, ACC), in: CGRect(x: x + cell - 100, y: y + 44 + BIG - ACC, width: ACC, height: ACC))
    drawText(sheet, d.0, size: 22, weight: .semibold, color: color(0xEDE7DC),
             center: CGPoint(x: x + cell/2 - 20, y: y + 20))
}
savePNG(sheet.makeImage()!, "complication-ideas.png")
print("書き出しました: complication-ideas.png")
