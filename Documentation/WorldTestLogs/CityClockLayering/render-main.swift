private struct ChapterAudit: View {
 let worldID:Int; let width:CGFloat; var time:TimeInterval = 0
 var size:CGSize { var result=WorldMapChapterSpacing.sceneSize(width:width); if worldID == 1 { result.height=offset+JungleMapLayout.firstNodeY+9*JungleMapLayout.levelSpacing+JungleMapLayout.bossReturnSpan(for:width) }; return result }
 var offset:CGFloat { WorldMapChapterSpacing.sceneOffset(width:width) }
 var body:some View {
  ZStack(alignment:.topLeading) {
   if worldID == 6 { CityAuditScene(width:width,time:time) }
   else if worldID == 1 { WorldMapLandscape(routeOffset:offset,viewportHeight:2500,cachesTerrain:true) }
   else { ThemedWorldLandscape(world:DinoWorldCatalog.world(worldID)!,routeOffset:offset,viewportHeight:2500) }
   if worldID != 5 {
    WorldRouteTrail(points:(worldID == 1 ? JungleMapLayout.levelPositions:WorldRouteTrail.chapterPositions).enumerated().map { CGPoint(x:(width-min(width,600)+36)/2+(min(width,600)-36)*$0.element,y:offset+(worldID == 1 ? 70:80)+CGFloat($0.offset)*175) },entryY:worldID == 1 ? nil:0,exitY:size.height,exitX:worldID == 1 ? width/2:nil)
   }
   if worldID == 8 { TimeMachineRouteForeground(routeOffset:offset,viewportHeight:2500) }
   WorldTitleBanner(world:DinoWorldCatalog.world(worldID)!,highContrast:false).frame(width:min(width,600)-36,height:212).position(x:width/2,y:118)
   ForEach(0..<10,id:\.self) { n in
    let rw=min(width,600)-36; let ps=worldID == 1 ? JungleMapLayout.levelPositions:WorldRouteTrail.chapterPositions
    Circle().fill(Color(dinoHex:0xC4D1AB)).overlay(Circle().stroke(Color(dinoHex:0x849B89),lineWidth:4)).overlay(Text("\((worldID-1)*10+n+1)").font(.system(size:24,weight:.bold)).foregroundStyle(Color(dinoHex:0x244958))).frame(width:n==9 ? 90:72,height:n==9 ? 90:72).position(x:(width-rw)/2+rw*ps[n],y:offset+(worldID == 1 ? 70:80)+CGFloat(n)*175)
   }
  }.frame(width:width,height:size.height)
 }
}

private struct CityAuditScene: View {
    let width: CGFloat
    let time: TimeInterval
    var body: some View {
        let l = CityGroundLayout.layout(width:width)
        ZStack(alignment:.topLeading) {
            Canvas { c,size in
                let depth = WorldSceneryDepth()
                CityWorldPainter(context:c).landscape(in:size,routeOffset:l.routeOffset,depth:depth)
                depth.draw()
            }
            CityMetroForeground(layout:l,line:CityMetroLine(layout:l),time:time,
                                viewport:CGRect(x:0,y:0,width:width,height:l.height),frozen:false,alwaysVisible:true)
        }.frame(width:width,height:l.height)
    }
}
private struct CityMaterialsAudit: View {
    let kinds: [CityUrbanLayout.Kind] = [.boulevard,.gabled,.arcade,.civic,.clockTower,.conservatory,.townhouse,.shop,.garden]
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<3,id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<3,id: \.self) { col in
                        let index = row*3+col
                        ZStack(alignment: .top) {
                            Color(dinoHex:0xDFE5D7)
                            Canvas { c,_ in
                                let site = CityUrbanLayout.Site(id:index,point:.init(x:120,y:270),size:1,right:false,kind:kinds[index])
                                CityWorldPainter(context:c).cityBuildingSite(site)
                            }
                            Text(["Boulevard","Woonhuis","Galerij","Stadshal","Klokkentoren","Serre","Herenhuis","Winkel","Tuin"][index])
                                .font(.system(size:15,weight:.semibold)).foregroundStyle(Color(dinoHex:0x244F64)).padding(.top,12)
                        }.frame(width:240,height:306)
                    }
                }
            }
        }.frame(width:720,height:918)
    }
}
@main struct CityClockLayeringAudit {
    @MainActor static func main() throws {
        let dir=URL(fileURLWithPath:CommandLine.arguments[1])
        try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
        func save<V:View>(_ view:V,_ name:String) throws {
            let renderer=ImageRenderer(content:view);renderer.scale=1.5
            guard let cg=renderer.cgImage else {fatalError("Render failed")}
            try NSBitmapImageRep(cgImage:cg).representation(using:.png,properties:[:])!.write(to:dir.appendingPathComponent(name+".png"))
        }
        let initial = WorldBossClock.time(in: 6)
        let first = CityClockPhase(elapsed: 0)
        precondition(first.reading == initial)
        precondition(abs(first.minuteAngle-initial.minuteAngle)<0.000001)
        precondition(abs(first.hourAngle-initial.hourAngle)<0.000001)
        for time in [0.0,0.05,1,2.5,5.99,24,270,288,1e8] {
            let a = CityClockPhase(elapsed: time), b = CityClockPhase(elapsed: time+0.05)
            let minuteAdvance = (b.minuteAngle-a.minuteAngle+360).truncatingRemainder(dividingBy:360)
            let hourAdvance = (b.hourAngle-a.hourAngle+360).truncatingRemainder(dividingBy:360)
            precondition(abs(minuteAdvance-0.75)<0.000001,"Minute hand must always advance clockwise")
            precondition(abs(hourAdvance-0.0625)<0.000001,"Hour hand must advance at 1/12 speed")
        }
        precondition(CityClockPhase(elapsed:270).reading == ClockTime(hour:0))
        precondition(CityClockPhase(elapsed:288).reading == initial.adding(minutes:720))
        print("PASS: shared initial time, forward motion, 24-second revolution, correct 12:1 gearing and day wrap")
        var geometry=""
        for w:CGFloat in [320,375,393,402,430,600,744,834,1024,1194] {
            let l=CityGroundLayout.layout(width:w), metro=CityMetroLine(layout:l)
            let sites=CityUrbanLayout.sites(layout:l)
            precondition(Set(sites.map(\.id)).count == sites.count)
            geometry += "width=\(w)\n"
            for site in sites {
                geometry += "\(site.id):\(site.kind.rawValue):\(site.point):\(site.size):\(site.right):\(site.bounds)\n"
                if !site.skyline && !site.coversMetroEntrance {
                    precondition(metro.groundIsClear(site.groundBounds,scale:l.scale),"Foundation on track")
                }
            }
            for d in stride(from:CGFloat(0),through:metro.length,by:10) {geometry += "rail=\(metro.pose(at:d).point)\n"}
            geometry += "boss=\(CityBossCourt(layout:l,line:metro).point)\n"
            print("\(Int(w))pt: \(sites.count) plots, foundations clear")
            if !CommandLine.arguments.contains("--geometry-only") && [393,402,834].contains(Int(w)) {
                try save(ChapterAudit(worldID:6,width:w),"world-6-\(Int(w))")
                for t in [0.0,2.5,6] {
                    let bottom=ChapterAudit(worldID:6,width:w,time:t).offset(y:-(l.routeOffset+1430))
                        .frame(width:w,height:520,alignment:.top).clipped()
                    try save(bottom,"lower-city-\(Int(w))-t\(t)")
                }
                let covers=sites.filter(\.coversMetroEntrance)
                for site in sites where site.point.y > (covers.map { $0.point.y }.max() ?? 0) && covers.contains(where: { $0.contentBounds.intersects(site.contentBounds) }) {
                    print("\(Int(w))pt: foreground building \(site.id) at y=\(site.point.y) naturally in front of tunnel houses \(covers.map { $0.point.y })")
                }
                let view=ChapterAudit(worldID:6,width:w,time:8).offset(y:-(l.routeOffset+460))
                    .frame(width:w,height:850,alignment:.top).clipped()
                try save(view,"stations-\(Int(w))")
            }
        }
        try geometry.write(to:dir.appendingPathComponent("geometry.txt"),atomically:true,encoding:.utf8)
        if !CommandLine.arguments.contains("--geometry-only") {try save(CityMaterialsAudit(),"buildings")}
        print("PASS: all city foundations clear at 10 widths")
    }
}
