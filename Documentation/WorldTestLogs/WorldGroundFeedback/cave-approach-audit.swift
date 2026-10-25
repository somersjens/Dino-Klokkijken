
@main struct AuditGrassCaveApproach {
    static func main() {
        AuditNativeWaterEndpoints.main()
        var checks = 0
        for width: CGFloat in [320,393,402,600,834,1194] {
            let size = WorldMapChapterSpacing.sceneSize(width: width)
            let offset = WorldMapChapterSpacing.sceneOffset(width: width)
            let layout = WorldSceneryLayout(width: width,height: size.height,routeOffset: offset)
            var lastWater: CGFloat = -400
            for right in [false,true] {
                for dy in stride(from: CGFloat(-400),through: 0,by: 1) {
                    let p = layout.villageCanalPoint(at: size.height-offset+dy,right:right)
                    if p.x+74*layout.scale > 0 && p.x-74*layout.scale < width { lastWater = max(lastWater,dy) }
                }
            }
            let firstStone = CrystalCaveLifeLayout.entranceStart(layout)-70*layout.scale
            precondition(firstStone > lastWater,"A cave entrance stone starts before the last river bank exits")
            checks += 1
            for right in [false,true] {
                for y in stride(from: CGFloat(-200),through: CrystalCaveLifeLayout.entranceStart(layout),by: 2) {
                    for distance: CGFloat in [102,127,131,189] {
                        let x = CrystalCaveLifeLayout.wallX(at:y,right:right,distance:distance,layout:layout)
                        precondition(right ? x-12*layout.scale > width : x+12*layout.scale < 0,
                                     "A wall projects into the grass before the river exit")
                        checks += 1
                    }
                }
            }
            print("\(Int(width))pt: last visible bank at \(Int(lastWater))pt; earliest possible entrance stone at +\(Int(firstStone))pt; both walls clear the outgoing village")
        }
        print("PASS: \(checks) cave entrance clearance checks")
    }
}
