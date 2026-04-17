#!/usr/bin/env swift
// Generates AppIcon.icns for SnapMark
// Usage: swift scripts/generate_icon.swift

import AppKit

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let s = size // shorthand

    // --- Background: rounded rectangle with gradient ---
    let cornerRadius = s * 0.22
    let bgRect = CGRect(x: 0, y: 0, width: s, height: s)
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()

    // Gradient: deep blue to purple
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        CGColor(red: 0.15, green: 0.25, blue: 0.65, alpha: 1.0),
        CGColor(red: 0.45, green: 0.20, blue: 0.70, alpha: 1.0),
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: s),
                               end: CGPoint(x: s, y: 0),
                               options: [])
    }
    ctx.restoreGState()

    // --- Crosshair / capture reticle ---
    let cx = s * 0.48
    let cy = s * 0.52
    let reticleRadius = s * 0.22
    let lineLen = s * 0.12
    let lineWidth = s * 0.035
    let gapRadius = s * 0.06

    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
    ctx.setLineWidth(lineWidth)
    ctx.setLineCap(.round)

    // Circle
    ctx.strokeEllipse(in: CGRect(x: cx - reticleRadius, y: cy - reticleRadius,
                                  width: reticleRadius * 2, height: reticleRadius * 2))

    // Crosshair lines (with gap in center)
    // Top
    ctx.move(to: CGPoint(x: cx, y: cy + gapRadius))
    ctx.addLine(to: CGPoint(x: cx, y: cy + reticleRadius + lineLen))
    ctx.strokePath()
    // Bottom
    ctx.move(to: CGPoint(x: cx, y: cy - gapRadius))
    ctx.addLine(to: CGPoint(x: cx, y: cy - reticleRadius - lineLen))
    ctx.strokePath()
    // Right
    ctx.move(to: CGPoint(x: cx + gapRadius, y: cy))
    ctx.addLine(to: CGPoint(x: cx + reticleRadius + lineLen, y: cy))
    ctx.strokePath()
    // Left
    ctx.move(to: CGPoint(x: cx - gapRadius, y: cy))
    ctx.addLine(to: CGPoint(x: cx - reticleRadius - lineLen, y: cy))
    ctx.strokePath()

    // --- Small pen/pencil stroke in bottom-right ---
    let penTip = CGPoint(x: s * 0.72, y: s * 0.22)
    let penEnd = CGPoint(x: s * 0.82, y: s * 0.35)
    ctx.setStrokeColor(CGColor(red: 1.0, green: 0.75, blue: 0.2, alpha: 1.0))
    ctx.setLineWidth(lineWidth * 1.2)
    ctx.setLineCap(.round)
    ctx.move(to: penTip)
    ctx.addLine(to: penEnd)
    ctx.strokePath()

    // Pen tip dot
    let dotR = s * 0.02
    ctx.setFillColor(CGColor(red: 1.0, green: 0.75, blue: 0.2, alpha: 1.0))
    ctx.fillEllipse(in: CGRect(x: penTip.x - dotR, y: penTip.y - dotR, width: dotR * 2, height: dotR * 2))

    image.unlockFocus()
    return image
}

func pngData(from image: NSImage) -> Data? {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff) else { return nil }
    return rep.representation(using: .png, properties: [:])
}

// Generate icon at required sizes
let sizes: [(String, Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

let iconsetDir = "/tmp/SnapMark.iconset"
let fm = FileManager.default
try? fm.removeItem(atPath: iconsetDir)
try fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

for (name, px) in sizes {
    let img = drawIcon(size: CGFloat(px))
    guard let data = pngData(from: img) else {
        print("Failed to generate \(name)")
        exit(1)
    }
    let path = "\(iconsetDir)/\(name).png"
    try data.write(to: URL(fileURLWithPath: path))
}

print("Iconset created at \(iconsetDir)")
print("Converting to .icns...")

let outputPath = "Resources/AppIcon.icns"
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["--convert", "icns", "--output", outputPath, iconsetDir]
try process.run()
process.waitUntilExit()

if process.terminationStatus == 0 {
    print("Icon created: \(outputPath)")
} else {
    print("iconutil failed with status \(process.terminationStatus)")
    exit(1)
}
