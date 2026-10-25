@main struct AuditNativeWaterEndpoints {
    static func main() {
        var checks = 0
        let widths: [CGFloat] = [320, 393, 402, 600, 834, 1194]
        for width in widths {
            let size = WorldMapChapterSpacing.sceneSize(width: width)
            let offset = WorldMapChapterSpacing.sceneOffset(width: width)
            let layout = WorldSceneryLayout(width: width, height: size.height, routeOffset: offset)
            func outside(_ point: CGPoint, radius: CGFloat, right: Bool, label: String) {
                checks += 1
                precondition(right ? point.x - radius > width : point.x + radius < 0,
                             "A \(label) bank still crosses the chapter edge at \(width)pt")
            }
            for right in [false, true] {
                for y in [-offset, size.height - offset] {
                    outside(layout.villageCanalPoint(at: y, right: right), radius: 74 * layout.scale, right: right, label: "village canal")
                    outside(SleepValleyLayout.streamPoint(y: y, right: right, layout: layout), radius: 70 * layout.scale, right: right, label: "sleep valley river")
                    outside(CastleKingdomLayout(scenery: layout).waterPoint(at: y, right: right), radius: 100 * layout.scale, right: right, label: "castle moat")
                    let sea = layout.pirateWaterArea(right: right)
                    for i in 0...40 {
                        checks += 1
                        precondition(!sea.contains(.init(x: width * CGFloat(i) / 40, y: y)),
                                     "The pirate inlet is still open at the chapter edge")
                    }
                }
                outside(VolcanoWorldLayout.channelPoint(layout: layout, right: right, y: size.height - offset),
                        radius: VolcanoWorldLayout.channelRockWidth(scale: layout.scale, width: width) / 2,
                        right: right, label: "volcanic lava channel")
                // The lava and basalt retain the original shared outgoing mouth.
                for sample in 0...50 {
                    let y = VolcanoWorldLayout.outletEnd(layout: layout, right: right) - offset + CGFloat(sample)
                    outside(VolcanoWorldLayout.channelPoint(layout: layout, right: right, y: y),
                            radius: 34 * layout.scale, right: right, label: "lava outlet")
                }
            }
            print("\(Int(width))pt: village canals, valley rivers, pirate inlets, castle moats and lava outlets clear both chapter edges")
        }
        print("PASS: \(checks) native water/riverbank endpoint checks; all banks exit through the sides, with no cross-chapter caps")
    }
}
