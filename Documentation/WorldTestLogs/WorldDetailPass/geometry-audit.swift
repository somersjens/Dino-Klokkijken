
@main struct AuditDetails {
 static func main() {
  AuditNativeWaterEndpoints.main()
  var checks=0
  for w:CGFloat in [320,393,402,600,834,1194] {
   let l=WorldSceneryLayout(width:w,height:WorldMapChapterSpacing.sceneSize(width:w).height,routeOffset:WorldMapChapterSpacing.sceneOffset(width:w))
   let city=CityInnerLayout.sites(layout:l)+CityInnerLayout.frontBlocks(layout:l)+CityInnerLayout.pocketSites(layout:l)+CityInnerLayout.endDistricts(layout:l)+CityInnerLayout.caveBlocks(layout:l)+CityInnerLayout.denseBlocks(layout:l)
   checks += 1;precondition(Set(city.map(\.id)).count == city.count,"City plot identifiers collide")
   let line=CityMetroLine(layout:l),tunnel=CityMetroTunnel(line:CityMetroLine(layout:l),scale:l.scale)
   for site in city {
    checks += 1;precondition(line.groundIsClear(site.groundBounds,scale:l.scale),"A facade foundation crosses an open railway")
    for i in 0...20 {
     let b=site.contentBounds,y=b.minY+b.height*CGFloat(i)/20,x=l.centerX(at:y)
     checks += 1;precondition(site.right ? b.minX>x+25*l.scale:b.maxX<x-25*l.scale,"Facade crosses the sand trail")
    }
   }
   for right in [false,true] {
    let end=VolcanoWorldLayout.inletEnd(layout:l,right:right)-l.routeOffset
    let a=VolcanoWorldLayout.channelPoint(layout:l,right:right,y:end-1),b=VolcanoWorldLayout.channelPoint(layout:l,right:right,y:end),c=VolcanoWorldLayout.channelPoint(layout:l,right:right,y:end+1)
    checks += 1;precondition(abs((b.x-a.x)-(c.x-b.x))<0.6,"Lava tangent breaks at the entrance join")
    let drain=TimeMachineLayout.terminals(layout:l).first{$0.right==right}!
    checks += 1;precondition(abs(drain.drainBounds.maxY-TimeMachineLayout.quayEnd(l))<0.01,"Drain and last stone course do not end together")
   }
   for distance in [tunnel.start,tunnel.end] {
    for side:CGFloat in [-1,1] {
     let a=tunnel.point(distance,lateral:side*29,surface:true),b=tunnel.point(distance,lateral:side*29)
     checks += 1;precondition(abs(a.x-b.x)<0.001 && abs(b.y-a.y-58*l.scale)<0.01,"Tunnel walls and portal disagree at the landing")
    }
   }
   let benches=VillagePlan.plots(layout:l).filter{$0.kind == .bench}
   for bench in benches { checks += 1;precondition(bench.bounds.height>bench.bounds.width,"Village bench is horizontal") }
   print("\(Int(w))pt: \(city.count) fitted city plots; \(CityUrbanLayout.sites(layout:l).count) larger city blocks; \(benches.count) upright benches; continuous lava and tunnel landings")
  }
  print("PASS: \(checks) geometry checks for city buildings, benches, lava and tunnel landings")
 }
}
