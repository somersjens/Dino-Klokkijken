
@main struct AuditVillageCityClock {
 static func main() {
  var checks=0
  for w:CGFloat in [320,393,402,600,834,1194] {
   let l=WorldSceneryLayout(width:w,height:WorldMapChapterSpacing.sceneSize(width:w).height,routeOffset:WorldMapChapterSpacing.sceneOffset(width:w))
   let metro=CityMetroLine(layout:l), tunnel=CityMetroTunnel(line:metro,scale:l.scale)
   let sites=CityInnerLayout.sites(layout:l)+CityInnerLayout.frontBlocks(layout:l)+CityInnerLayout.pocketSites(layout:l)+CityInnerLayout.endDistricts(layout:l)+CityInnerLayout.caveBlocks(layout:l)+CityInnerLayout.denseBlocks(layout:l)
   checks += 1; precondition(Set(sites.map(\.id)).count == sites.count,"Duplicate city identifiers")
   let rightMouth=tunnel.arch(at:tunnel.end,radius:29,crown:73).boundingRect
   checks += 1; precondition(rightMouth.minX>w,"Right portal has not left the visible street")
   for site in sites {
    checks += 1; precondition(metro.groundIsClear(site.groundBounds,scale:l.scale),"Building foundation crosses exposed tracks")
    let b=site.contentBounds
    for n in 0...60 {
     let y=b.minY+b.height*CGFloat(n)/60, center=l.centerX(at:y)
     checks += 1; precondition(site.right ? b.minX>center+25*l.scale:b.maxX<center-25*l.scale,"City facade crosses trail")
    }
   }
   let foreground=sites.filter(\.foreground)
   let leftMouth=tunnel.arch(at:tunnel.start,radius:20,crown:56).boundingRect
   checks += 1; precondition(foreground.contains{$0.contentBounds.contains(CGPoint(x:leftMouth.midX,y:leftMouth.midY))},"Left portal lacks a foreground facade")
   for d in [tunnel.start,tunnel.end] {
    for side:CGFloat in [-1,1] {
     let a=tunnel.point(d,lateral:side*29,surface:true), b=tunnel.point(d,lateral:side*29)
     checks += 1; precondition(abs(a.x-b.x)<0.001 && abs(b.y-a.y-58*l.scale)<0.001,"Tunnel wall does not meet portal floor")
    }
   }
   let benches=VillagePlan.plots(layout:l).filter{$0.kind == .bench}
   for bench in benches {checks += 1;precondition(bench.bounds.height>bench.bounds.width,"Bench is horizontal")}
   for right in [false,true] {for outer in [false,true] {
    let walkway=l.villageCanalPath(right:right,inset:34-(outer ? 35:-35)).strokedPath(StrokeStyle(lineWidth:21*l.scale))
    for y in stride(from:CGFloat(-35),through:1650,by:9) {
     checks += 1;precondition(walkway.contains(l.villageQuayPoint(at:y,right:right,outer:outer)),"A doorway starts outside the paved quay")
    }
   }}
   for assembly in TimeMachineLayout.assemblies(layout:l) {
    let front=assembly.selectingGears(true), back=assembly.selectingGears(false)
    checks += 1;precondition((front?.parts.count ?? 0)+(back?.parts.count ?? 0)==assembly.parts.count,"Machinery loses a moving part between layers")
   }
   print("\(Int(w))pt: \(sites.count) city plots, \(CityInnerLayout.caveBlocks(layout:l).count) cave-front buildings, \(benches.count) upright benches; right portal outside, left portal behind facades; joined quays and complete gears")
  }
  print("PASS: \(checks) geometry checks")
 }
}
