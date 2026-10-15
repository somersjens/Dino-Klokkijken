import Foundation
import CoreGraphics
import ImageIO
import CryptoKit

@main
struct RenderBenchmark {
    static func main() throws {
        let assets = ["dino-idle", "dino-thumbs-up-08", "dino-wrong-answer-04", "dino-backflip-01", "dino-backflip-03", "dino-backflip-07", "dino-backflip-08"]
        let appearances = [DinoAppearance.standard, DinoAppearance(bandana: 0x459CDF, spikes: 0xA77BE0, body: 0xF48EB6, belly: 0xF59A32)]
        for appearance in appearances {
            var elapsed: Double = 0
            for asset in assets {
                let url = URL(fileURLWithPath: "Assets.xcassets/\(asset).imageset/\(asset).png")
                let source = CGImageSourceCreateWithURL(url as CFURL, nil)!
                let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
                let start = ProcessInfo.processInfo.systemUptime
                let result = DinoSpriteColorRenderer.recolored(image, appearance: appearance, asset: asset)!
                let duration = ProcessInfo.processInfo.systemUptime - start
                elapsed += duration
                let data = result.dataProvider!.data! as Data
                let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
                print("\(asset) \(appearance.body) \(String(format: "%.6f", duration)) \(digest)")
            }
            print("TOTAL \(appearance.body) \(String(format: "%.6f", elapsed))")
        }
    }
}
