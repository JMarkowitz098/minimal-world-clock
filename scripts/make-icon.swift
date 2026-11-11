// Renders the app icon at every macOS size into the Mac asset catalog.
// Usage: swift scripts/make-icon.swift
// Design "G", chosen by the user in M10 from an option sheet: a cream dial on navy, hands at
// 10:10 with an orange minute hand. Drawn from plain shapes: SF Symbols may not be used in app
// icons (Apple's license). Cream and orange are Solarized's (Ethan Schoonover, MIT, credited in
// Apps/Mac/Credits.rtf); the navy is ours.
import AppKit

// MARK: - Colors

func rgb(_ hex: Int) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

let cream = rgb(0xFDF6E3)   // Solarized base3
let orange = rgb(0xCB4B16)  // Solarized orange
let navy = rgb(0x1B2A4A)

// MARK: - Template

/// macOS icon grid: an 824-point body centered in the 1024-point canvas, ~185-point corners.
let body = NSRect(x: 100, y: 100, width: 824, height: 824)
let center = NSPoint(x: 512, y: 512)

func fillBody(_ color: NSColor) {
    let shape = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = .black.withAlphaComponent(0.3)
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.shadowBlurRadius = 24
    shadow.set()
    color.setFill()
    shape.fill()
    NSGraphicsContext.restoreGraphicsState()
}

func circle(_ c: NSPoint, _ r: CGFloat) -> NSBezierPath {
    NSBezierPath(ovalIn: NSRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
}

/// A point at `minutes` past twelve on a 60-minute dial.
func dial(_ c: NSPoint, _ r: CGFloat, minutes: CGFloat) -> NSPoint {
    let a = (90 - minutes * 6) * .pi / 180
    return NSPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
}

func hand(_ c: NSPoint, to p: NSPoint, width: CGFloat, color: NSColor) {
    let path = NSBezierPath()
    path.move(to: c)
    path.line(to: p)
    path.lineWidth = width
    path.lineCapStyle = .round
    color.setStroke()
    path.stroke()
}

// MARK: - Design

/// A cream dial on navy with the hands at 10:10 (the watchmakers' resting time): a navy hour
/// hand and an orange minute hand.
func drawIcon() {
    fillBody(navy)
    cream.setFill()
    circle(center, 300).fill()
    hand(center, to: dial(center, 160, minutes: 50 + 10 / 12 * 5), width: 34, color: navy)
    hand(center, to: dial(center, 236, minutes: 10), width: 34, color: orange)
    navy.setFill()
    circle(center, 30).fill()
}

// MARK: - Rendering

/// Draws the icon directly at `pixels` resolution (vector, so small sizes stay crisp).
func render(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: 1024, height: 1024)  // draw in 1024-point design space
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    drawIcon()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let catalog = "Apps/Mac/Assets.xcassets"
let output = "\(catalog)/AppIcon.appiconset"
let pixelSizes = [16, 32, 64, 128, 256, 512, 1024]
try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
for pixels in pixelSizes {
    try render(pixels: pixels).write(to: URL(fileURLWithPath: "\(output)/icon_\(pixels).png"))
}

// Each point size needs a 1x and 2x image.
let entries = [16, 32, 128, 256, 512].flatMap { points in
    [1, 2].map { scale in
        """
            { "idiom" : "mac", "size" : "\(points)x\(points)", "scale" : "\(scale)x", "filename" : "icon_\(points * scale).png" }
        """
    }
}
let contents = """
{
  "images" : [
\(entries.joined(separator: ",\n"))
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
"""
try contents.write(toFile: "\(output)/Contents.json", atomically: true, encoding: .utf8)
try #"{ "info" : { "author" : "xcode", "version" : 1 } }"#
    .write(toFile: "\(catalog)/Contents.json", atomically: true, encoding: .utf8)
print("Wrote \(pixelSizes.count) icons to \(output)")
