private struct TunnelPreview: View {
    let width: CGFloat
    let time: TimeInterval
    var layout: WorldSceneryLayout {
        WorldSceneryLayout(width:width,height:WorldMapChapterSpacing.sceneSize(width:width).height,
                           routeOffset:WorldMapChapterSpacing.sceneOffset(width:width))
    }
    var body: some View {
        let l=layout
        ZStack(alignment:.topLeading) {
            Canvas { c,size in
                let depth=WorldSceneryDepth()
                CityWorldPainter(context:c).landscape(in:size,routeOffset:l.routeOffset,depth:depth)
                depth.draw()
            }
            CityMetroForeground(layout:l,line:CityMetroLine(layout:l),time:time,
                                viewport:CGRect(x:0,y:0,width:width,height:l.height),frozen:false,alwaysVisible:true)
            WorldRouteTrail(points:WorldRouteTrail.chapterPositions.enumerated().map {
                CGPoint(x:(width-min(width,600)+36)/2+(min(width,600)-36)*$0.element,
                        y:l.routeOffset+80+CGFloat($0.offset)*175)
            },entryY:0,exitY:l.height)
            ForEach(7..<10,id:\.self) { n in
                Circle().fill(Color(dinoHex:0xC4D1AB))
                    .overlay(Circle().stroke(Color(dinoHex:0x849B89),lineWidth:4))
                    .overlay(Text("\(51+n)").font(.system(size:24,weight:.bold)).foregroundStyle(Color(dinoHex:0x244958)))
                    .frame(width:n == 9 ? 90:72,height:n == 9 ? 90:72)
                    .position(x:(width-min(width,600)+36)/2+(min(width,600)-36)*WorldRouteTrail.chapterPositions[n],
                              y:l.routeOffset+80+CGFloat(n)*175)
            }
        }.frame(width:width,height:l.height)
            .offset(y:-(l.routeOffset+1230)).frame(width:width,height:620,alignment:.top).clipped()
    }
}
@main struct TunnelAudit {
    @MainActor static func main() throws {
        let folder=URL(fileURLWithPath:CommandLine.arguments[1])
        for w:CGFloat in [320,375,393,402,430,600,744,834,1024,1194] {
            let l=WorldSceneryLayout(width:w,height:WorldMapChapterSpacing.sceneSize(width:w).height,
                                    routeOffset:WorldMapChapterSpacing.sceneOffset(width:w))
            let line=CityMetroLine(layout:l), tunnel=CityMetroTunnel(line:line,scale:l.scale)
            for d in [tunnel.start,tunnel.end] {
                let arch=tunnel.arch(at:d,radius:41,crown:73).boundingRect
                precondition(arch.minX>0 && arch.maxX<w,"Tunnel mouth outside screen at \(w): \(arch)")
                precondition(abs(tunnel.depth(at:d)-58*l.scale)<0.001)
            }
            precondition(tunnel.depth(at:tunnel.rampStart)<0.001 && tunnel.depth(at:tunnel.rampEnd)<0.001)
            for d in stride(from:tunnel.end,through:tunnel.rampEnd,by:2*l.scale) {
                let p=tunnel.carriagePose(at:d).point
                precondition(p.x>24*l.scale && p.x<w-24*l.scale,"Emerging metro outside screen at \(w)")
                precondition(p.y+l.routeOffset<l.height-35*l.scale,"Emergence below city edge")
            }
            let sites=CityUrbanLayout.sites(layout:l)
            precondition(Set(sites.map(\.id)).count==sites.count)
            for site in sites {
                precondition(line.groundIsClear(site.groundBounds,scale:l.scale),"Foundation on exposed rails")
                precondition(!tunnel.approachClearances.contains{$0.intersects(site.contentBounds)},"Facade hides approach")
            }
            print("\(Int(w))pt: both portals visible; complete climb on screen; \(sites.count) city plots clear of approaches and rails")
            if [320,393,834].contains(Int(w)) {
                for (index,d) in [tunnel.start-45*l.scale,tunnel.start+45*l.scale,tunnel.end+35*l.scale,tunnel.end+110*l.scale].enumerated() {
                    var low=0.0, high=45.0
                    for _ in 0..<40 { let mid=(low+high)/2; if line.travel(at:mid,scale:l.scale).distance<d {low=mid} else {high=mid} }
                    let renderer=ImageRenderer(content:TunnelPreview(width:w,time:(low+high)/2));renderer.scale=2
                    guard let cg=renderer.cgImage else {fatalError("Render failed")}
                    try NSBitmapImageRep(cgImage:cg).representation(using:.png,properties:[:])!.write(to:folder.appendingPathComponent("tunnel-\(Int(w))-\(index).png"))
                }
            }
        }
        print("PASS: tunnel visibility and building clearances on 10 widths")
    }
}
