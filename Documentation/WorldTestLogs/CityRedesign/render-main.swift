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
@main struct CityRedesignAudit {
    @MainActor static func main() throws {
        let dir = URL(fileURLWithPath:CommandLine.arguments[1])
        try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
        func save<V:View>(_ view:V,_ name:String) throws {
            let renderer = ImageRenderer(content:view); renderer.scale = 1.5
            guard let cg = renderer.cgImage else { fatalError("Render failed") }
            try NSBitmapImageRep(cgImage:cg).representation(using:.png,properties:[:])!.write(to:dir.appendingPathComponent(name+".png"))
        }
        for w:CGFloat in [320,375,393,402,430,600,744,834,1024,1194] {
            let l = CityGroundLayout.layout(width:w), s = l.scale
            let line = CityMetroLine(layout:l), tunnel = CityMetroTunnel(line:line,scale:s)
            let sites = CityUrbanLayout.sites(layout:l)
            precondition(Set(sites.map(\.id)).count == sites.count)
            precondition(tunnel.arch(at:tunnel.end,radius:41,crown:73).boundingRect.minX>w+40*s,"Visible return portal at \(w)")
            for d in stride(from:tunnel.end,through:tunnel.rampEnd,by:2*s) {
                precondition(tunnel.carriagePose(at:d).point.x>w+40*s,"Visible return climb at \(w)")
            }
            precondition(tunnel.depth(at:tunnel.rampStart)<0.001 && tunnel.depth(at:tunnel.rampEnd)<0.001)
            precondition(abs(tunnel.depth(at:tunnel.start)-58*s)<0.001)
            let arch = tunnel.arch(at:tunnel.start,radius:29,crown:73).boundingRect
            let covers = sites.filter(\.coversMetroEntrance)
            print("\(Int(w))pt: \(sites.count) plots; left portal \(arch); covers \(covers.map(\.contentBounds)); return climb x=\(tunnel.floorPoint(at:tunnel.rampEnd).x)")
            let mouth = tunnel.arch(at:tunnel.start,radius:21,crown:62)
            var uncovered = 0
            for x in stride(from:mouth.boundingRect.minX,through:mouth.boundingRect.maxX,by:s) {
                for y in stride(from:mouth.boundingRect.minY,through:mouth.boundingRect.maxY,by:s) {
                    let point = CGPoint(x:x,y:y)
                    guard mouth.contains(point) else { continue }
                    let hidden = covers.contains { site in
                        let local = CGPoint(x:(x-site.point.x)/site.size,y:(y-site.point.y)/site.size)
                        var roof = Path(); roof.addLines([.init(x:-34,y:-59),.init(x:-24,y:-77),.init(x:23,y:-77),.init(x:34,y:-59)]); roof.closeSubpath()
                        return CGRect(x:-29,y:-61,width:58,height:64).contains(local) || roof.contains(local)
                            || CGRect(x:-37,y:-8,width:74,height:21).contains(local)
                    }
                    if !hidden { uncovered += 1 }
                }
            }
            precondition(uncovered == 0,"Exposed portal behind shops at \(w): \(uncovered) samples")
            print("Portal fully concealed by opaque facades")
            let skyline = sites.filter(\.skyline)
            for x in stride(from:CGFloat(0),through:w,by:2) {
                precondition(skyline.contains { site in
                    let body = CGRect(x:site.point.x-37*site.size,y:site.point.y-111*site.size,width:74*site.size,height:114*site.size)
                    return body.contains(.init(x:x,y:155-l.routeOffset))
                },"Gap in header frontage at \(w), x=\(x)")
            }
            for site in sites where !site.skyline && !site.coversMetroEntrance {
                precondition(line.groundIsClear(site.groundBounds,scale:s),"Foundation on open railway")
                precondition(!tunnel.approachClearances.contains { $0.intersects(site.contentBounds) },"Facade hides open descent")
            }
            if !CommandLine.arguments.contains("--geometry-only") && [320,393,834,1194].contains(Int(w)) {
                let h = l.height
                let join = VStack(spacing:0) { ChapterAudit(worldID:5,width:w); ChapterAudit(worldID:6,width:w) }
                    .offset(y:-(h-350)).frame(width:w,height:920,alignment:.top).clipped()
                try save(join,"join-5-\(Int(w))")
                try save(ChapterAudit(worldID:6,width:w),"world-6-\(Int(w))")
                for (index,d) in [tunnel.start-85*s,tunnel.start+40*s,tunnel.end+300*s].enumerated() {
                    var low = 0.0, high = 0.1
                    while line.travel(at:high,scale:s).distance<d && high<120 { low=high;high+=0.1 }
                    for _ in 0..<40 { let mid = (low+high)/2; if line.travel(at:mid,scale:s).distance<d {low=mid} else {high=mid} }
                    let view = ChapterAudit(worldID:6,width:w,time:(low+high)/2)
                        .offset(y:-(l.routeOffset+1230)).frame(width:w,height:660,alignment:.top).clipped()
                    try save(view,"metro-\(Int(w))-\(index)")
                }
            }
        }
        print("PASS: continuous skyline, hidden return/climb, free railway and playable streets at 10 widths")
    }
}
