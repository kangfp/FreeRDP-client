#!/usr/bin/env swift
// 生成应用图标: 蓝色渐变圆角方块 + 白色显示器 + 双向箭头
// 用法: swift scripts/generate_icon.swift <输出PNG路径>
import AppKit
import CoreGraphics

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/AppIcon.png"
let size: CGFloat = 1024

guard let ctx = CGContext(
    data: nil, width: Int(size), height: Int(size),
    bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("无法创建绘图上下文") }

// ---- 背景: macOS 风格圆角方块 ----
let margin: CGFloat = 100
let bgRect = CGRect(x: margin, y: margin, width: size - 2 * margin, height: size - 2 * margin)
let bgPath = CGPath(roundedRect: bgRect, cornerWidth: 185, cornerHeight: 185, transform: nil)
ctx.saveGState()
ctx.addPath(bgPath)
ctx.clip()
let gradient = CGGradient(
    colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
    colors: [
        CGColor(red: 0.30, green: 0.62, blue: 1.00, alpha: 1),
        CGColor(red: 0.07, green: 0.28, blue: 0.72, alpha: 1),
    ] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(gradient,
                       start: CGPoint(x: 0, y: size),
                       end: CGPoint(x: size, y: 0),
                       options: [])
ctx.restoreGState()

// ---- 显示器 ----
let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
let screenDark = CGColor(red: 0.05, green: 0.18, blue: 0.45, alpha: 1)

// 外壳 (白色圆角矩形)
let monitorRect = CGRect(x: 252, y: 400, width: 520, height: 360)
let monitorPath = CGPath(roundedRect: monitorRect, cornerWidth: 36, cornerHeight: 36, transform: nil)
ctx.addPath(monitorPath)
ctx.setFillColor(white)
ctx.fillPath()

// 屏幕 (深蓝)
let screenRect = monitorRect.insetBy(dx: 26, dy: 26)
let screenPath = CGPath(roundedRect: screenRect, cornerWidth: 18, cornerHeight: 18, transform: nil)
ctx.addPath(screenPath)
ctx.setFillColor(screenDark)
ctx.fillPath()

// 支架
ctx.setFillColor(white)
ctx.fill(CGRect(x: 472, y: 330, width: 80, height: 76))
let baseRect = CGRect(x: 392, y: 300, width: 240, height: 34)
ctx.addPath(CGPath(roundedRect: baseRect, cornerWidth: 17, cornerHeight: 17, transform: nil))
ctx.fillPath()

// ---- 屏幕内双向箭头 ----
func drawArrow(y: CGFloat, leftToRight: Bool, color: CGColor) {
    let x0: CGFloat = 340, x1: CGFloat = 684
    let shaftWidth: CGFloat = 26
    let headLen: CGFloat = 62, headHalf: CGFloat = 44
    ctx.setFillColor(color)
    if leftToRight {
        ctx.fill(CGRect(x: x0, y: y - shaftWidth / 2, width: x1 - x0 - headLen + 10, height: shaftWidth))
        ctx.move(to: CGPoint(x: x1, y: y))
        ctx.addLine(to: CGPoint(x: x1 - headLen, y: y + headHalf))
        ctx.addLine(to: CGPoint(x: x1 - headLen, y: y - headHalf))
        ctx.closePath()
        ctx.fillPath()
    } else {
        ctx.fill(CGRect(x: x0 + headLen - 10, y: y - shaftWidth / 2, width: x1 - x0 - headLen + 10, height: shaftWidth))
        ctx.move(to: CGPoint(x: x0, y: y))
        ctx.addLine(to: CGPoint(x: x0 + headLen, y: y + headHalf))
        ctx.addLine(to: CGPoint(x: x0 + headLen, y: y - headHalf))
        ctx.closePath()
        ctx.fillPath()
    }
}
let green = CGColor(red: 0.35, green: 0.90, blue: 0.55, alpha: 1)
drawArrow(y: 640, leftToRight: true, color: white)
drawArrow(y: 520, leftToRight: false, color: green)

// ---- 输出 PNG ----
guard let cgImage = ctx.makeImage() else { fatalError("无法生成图像") }
let rep = NSBitmapImageRep(cgImage: cgImage)
guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("无法编码 PNG") }
let url = URL(fileURLWithPath: outPath)
try! FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
try! png.write(to: url)
print("图标已生成: \(outPath)")
