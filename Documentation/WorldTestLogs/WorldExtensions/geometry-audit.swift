
@main struct AuditWorldExtensions {
    static func main() {
        AuditNativeWaterEndpoints.main()
        var checks = 0
        func check(_ result: Bool, _ message: String) {
            checks += 1
            precondition(result, message)
        }
        for w: CGFloat in [320, 393, 402, 600, 834, 1194] {
            let size = WorldMapChapterSpacing.sceneSize(width: w)
            let offset = WorldMapChapterSpacing.sceneOffset(width: w)
            let layout = WorldSceneryLayout(width: w, height: size.height, routeOffset: offset)
            let s = layout.scale
            let line = CityMetroLine(layout: layout)
            let arrival = CityInnerLayout.caveBlocks(layout: layout)
            let lower = CityInnerLayout.endDistricts(layout: layout).filter { $0.id >= 450 }
            check(arrival.count == 4, "Missing cave-side city facades")
            check(lower.contains { !$0.right } && lower.contains { $0.right }, "Missing buildings beside lower metro")
            for site in arrival + lower {
                check(line.groundIsClear(site.groundBounds, scale: s), "City building touches railway")
                check(site.contentBounds.minX > 0 && site.contentBounds.maxX < w, "City facade clipped horizontally")
                for i in 0...36 {
                    let y = site.contentBounds.minY + site.contentBounds.height * CGFloat(i) / 36
                    let x = layout.centerX(at: y)
                    check(site.right ? site.contentBounds.minX >= x + 44 * s : site.contentBounds.maxX <= x - 44 * s,
                          "City facade touches the route")
                }
            }
            let field = TimeMachineLayout.waterField(layout: layout)
            let end = TimeMachineLayout.quayEnd(layout)
            for terminal in field.terminals {
                check(abs(terminal.drainBounds.maxY - end) < 0.01, "Masonry/drain endpoint mismatch")
                check(abs(field.transitionBounds.maxY - end) < 0.01, "Drain cut by end mask")
                check(terminal.sourceBounds.minY + offset > 0, "Springhouse roof clipped at chapter top")
            }
            check(TimeMachineLayout.firstTerrace(layout) + offset - 287*s > 0,
                  "First clock-tower roof clipped at chapter top")
            for right in [false, true] {
                let atBoundary = CrystalCaveLifeLayout.departureProgress(at: size.height, right: right, layout: layout)
                check(atBoundary > 0 && atBoundary < 1, "Cave wall ends before city begins")
                check(CrystalCaveLifeLayout.departureProgress(at: size.height + 260*s, right: right, layout: layout) == 1,
                      "Cave wall does not finish in city approach")
                for distance: CGFloat in [102, 127, 131, 189] {
                    let a = CrystalCaveLifeLayout.wallX(at: size.height - 0.01, right: right, distance: distance, layout: layout)
                    let b = CrystalCaveLifeLayout.wallX(at: size.height + 0.01, right: right, distance: distance, layout: layout)
                    check(abs(a-b) < 1, "Cave wall discontinuity at chapter boundary")
                }
            }
            print("\(Int(w))pt: \(arrival.count) cave-side facades; lower metro: \(lower.map { String(format: "%.2f", Double($0.size/s)) }.joined(separator: ", ")); drain and masonry aligned; intact first roofs")
        }
        print("PASS: \(checks) world-extension geometry checks")
    }
}
