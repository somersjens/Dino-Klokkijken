import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Retain the full source outside the app; ship a transparent 640-point square.
let replacements = [(3, "boss-volcano"), (5, "boss-crystal-cave"), (9, "boss-pirates"), (10, "boss-castle")]
for (number, asset) in replacements {
    let sourceURL = URL(fileURLWithPath: "Assets.xcassets/new_\(number).imageset/new_\(number).png")
    let archive = URL(fileURLWithPath: "Documentation/Eindbazen/References/new_\(number)-original.png")
    let input = FileManager.default.fileExists(atPath: sourceURL.path) ? sourceURL : archive
    let source = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(input as CFURL, nil)!, 0, nil)!
    if !FileManager.default.fileExists(atPath: archive.path) { try FileManager.default.copyItem(at: input, to: archive) }
    let width = source.width, height = source.height
    let format = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    let prepared = pixels.withUnsafeMutableBytes { buffer -> CGImage in
        let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: format)!
        context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
        let bytes = buffer.bindMemory(to: UInt8.self)
        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                if bytes[i + 3] < 16 { for c in 0..<4 { bytes[i + c] = 0 }; continue }
                guard number == 3 else { continue }
                // Cut only dark red dial paint. Orange fingers and the complete gold bezel stay opaque.
                let r = Double(bytes[i]), g = Double(bytes[i + 1]), b = Double(bytes[i + 2])
                let openings: [(Double, Double, Double, Double)] = [(355, 885, 45, 62), (501.5, 808, 61, 60), (661, 710, 57, 57)]
                if r > 55, g < r * 0.30, b < r * 0.28,
                   openings.contains(where: { pow((Double(x) - $0.0) / $0.2, 2) + pow((Double(y) - $0.1) / $0.3, 2) < 1 }) {
                    for c in 0..<4 { bytes[i + c] = 0 }
                }
            }
        }
        return context.makeImage()!
    }
    let side = 640
    let context = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: format)!
    let scale = Double(side) / Double(max(width, height))
    context.interpolationQuality = .high
    context.draw(prepared, in: CGRect(x: (Double(side) - Double(width) * scale) / 2,
        y: (Double(side) - Double(height) * scale) / 2, width: Double(width) * scale, height: Double(height) * scale))
    let output = URL(fileURLWithPath: "Assets.xcassets/\(asset).imageset/\(asset).png")
    let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    precondition(CGImageDestinationFinalize(destination))
    if FileManager.default.fileExists(atPath: sourceURL.path) { try FileManager.default.removeItem(at: sourceURL.deletingLastPathComponent()) }
    print("\(asset): \(width)×\(height) → 640×640")
}
