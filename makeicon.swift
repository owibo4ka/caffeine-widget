import AppKit

// Renders a 1024×1024 coffee-cup app icon to the path given as arg 1.
let size: CGFloat = 1024

// Tint a template image white in its OWN transparent layer, so the
// sourceAtop fill only touches the symbol's pixels (not the background).
func tintedWhite(_ image: NSImage) -> NSImage {
    let out = NSImage(size: image.size)
    out.lockFocus()
    let r = NSRect(origin: .zero, size: image.size)
    image.draw(in: r, from: r, operation: .sourceOver, fraction: 1)
    NSColor.white.set()
    r.fill(using: .sourceAtop)
    out.unlockFocus()
    return out
}

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

// Warm rounded-rect background with a latte gradient.
let rect = NSRect(x: 0, y: 0, width: size, height: size)
let bg = NSBezierPath(roundedRect: rect, xRadius: size * 0.225, yRadius: size * 0.225)
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.91, green: 0.71, blue: 0.53, alpha: 1.0), // cream top
    NSColor(calibratedRed: 0.55, green: 0.34, blue: 0.21, alpha: 1.0), // espresso bottom
])!
gradient.draw(in: bg, angle: -90)

// White coffee-cup symbol, centered.
let config = NSImage.SymbolConfiguration(pointSize: 560, weight: .semibold)
if let sym = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: nil)?
    .withSymbolConfiguration(config) {
    sym.isTemplate = true
    let cup = tintedWhite(sym)
    let origin = NSPoint(x: (size - cup.size.width) / 2,
                         y: (size - cup.size.height) / 2 - size * 0.02)
    cup.draw(at: origin, from: NSRect(origin: .zero, size: cup.size),
             operation: .sourceOver, fraction: 1)
}

image.unlockFocus()

if let tiff = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiff),
   let png = bitmap.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
}
