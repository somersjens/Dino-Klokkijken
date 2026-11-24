import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Slice the generated 4×2 sheets into the app's individual, square sprite assets.
// Usage: swift Tools/import-jungle-sprites.swift reactions.png acrobatics.png turn.png
let names = [
    ["jungle-idle", "jungle-wrong", "jungle-clap-open", "jungle-clap-contact",
     "jungle-clap-open-2", "jungle-clap-contact-2"],
    ["jungle-crouch", "jungle-takeoff", "jungle-airborne", "jungle-landing",
     "jungle-recover", "jungle-stumble", "jungle-fallen", "jungle-push-up"],
    (1...8).map { String(format: "jungle-turn-%02d", $0) }
]
precondition(CommandLine.arguments.count == 4, "Provide the reactions, acrobatics and turn sheets")
for (sheet, path) in CommandLine.arguments.dropFirst().enumerated() {
    let url = URL(fileURLWithPath: path)
    let source = CGImageSourceCreateWithURL(url as CFURL, nil)!
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
    for (index, name) in names[sheet].enumerated() {
        let x0 = Int((Double(index % 4) * Double(image.width) / 4).rounded())
        let x1 = Int((Double(index % 4 + 1) * Double(image.width) / 4).rounded())
        let y0 = Int((Double(index / 4) * Double(image.height) / 2).rounded())
        let y1 = Int((Double(index / 4 + 1) * Double(image.height) / 2).rounded())
        let cell = image.cropping(to: CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0))!
        let side = 512
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let output = pixels.withUnsafeMutableBytes { buffer -> CGImage in
            let context = CGContext(data: buffer.baseAddress, width: side, height: side,
                bitsPerComponent: 8, bytesPerRow: side * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.interpolationQuality = .high
            context.draw(cell, in: CGRect(x: 0, y: 0, width: side, height: side))
            // Discard near-transparent export noise while retaining the generated silhouette alpha.
            let bytes = buffer.bindMemory(to: UInt8.self)
            for pixel in stride(from: 0, to: bytes.count, by: 4) where bytes[pixel + 3] < 16 {
                for channel in 0..<4 { bytes[pixel + channel] = 0 }
            }
            return context.makeImage()!
        }
        let directory = URL(fileURLWithPath: "Assets.xcassets/\(name).imageset")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination = CGImageDestinationCreateWithURL(directory.appendingPathComponent("\(name).png") as CFURL,
                                                        UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, output, nil)
        precondition(CGImageDestinationFinalize(destination))
        let manifest: [String: Any] = ["images": [["filename": "\(name).png", "idiom": "universal"]],
                                       "info": ["author": "xcode", "version": 1]]
        try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
            .write(to: directory.appendingPathComponent("Contents.json"))
    }
}
print("Imported 22 jungle character sprites")
