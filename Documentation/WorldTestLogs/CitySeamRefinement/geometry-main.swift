
@main struct AuditCitySeams {
 static func main() {
  var checks=0
  for w:CGFloat in [320,375,393,430,600,744,834,1024,1194] {
   let l=CityGroundLayout.layout(width:w),s=l.scale
   let metro=CityMetroLine(layout:l),tunnel=CityMetroTunnel(line:metro,scale:s)
   let sites=CityUrbanLayout.sites(layout:l)
   checks += 1;precondition(Set(sites.map(\.id)).count==sites.count,"Duplicate city plot")
   let court=CityBossCourt(layout:l,line:metro).groundBounds.insetBy(dx:-12*s,dy:-15*s)
   let platforms=metro.stationDistances.map{metro.ribbon(from:$0-111*s,to:$0+111*s,inner:18*s,outer:91*s).boundingRect.insetBy(dx:-8*s,dy:-15*s)}
   for site in sites {
    checks += 3
    precondition(metro.groundIsClear(site.groundBounds.insetBy(dx:-5*s,dy:-3*s),scale:s),"Facade footing crosses open track")
    precondition(!site.groundBounds.intersects(court),"Facade crosses robot court")
    precondition(!platforms.contains{$0.intersects(site.groundBounds)},"Facade crosses station platform")
    for i in 0...150 {
     let b=site.contentBounds,y=b.minY+b.height*CGFloat(i)/150,center=l.centerX(at:y)
     checks += 1;precondition(site.right ? b.minX>center+60.7*s:b.maxX<center-60.7*s,"Full facade crosses promenade")
    }
   }
   for site in sites where site.kind == .clockTower {
    checks += 1;precondition(site.contentBounds.minY+l.routeOffset>=320,"Clock tower is still in the cave")
   }
   checks += 1;precondition(sites.contains{$0.id == 25000},"Left tunnel has no reserved frontage")
   let arrival=sites.filter(\.arrival)
   checks += 2;precondition(arrival.contains{$0.contentBounds.minY+l.routeOffset<0},"Skyline does not reach into cave")
   precondition(arrival.allSatisfy{$0.contentBounds.minY+l.routeOffset > -140*s-0.01},"Skyline reaches the cave boss")
   let last=CityGroundLayout.lastFrontages(layout:l)
   for site in last {
    for i in 0...24 {
     let x=max(0,min(w,site.groundBounds.minX+site.groundBounds.width*CGFloat(i)/24))
     guard x>=site.groundBounds.minX,x<=site.groundBounds.maxX else{continue}
     checks += 1;precondition(CityGroundLayout.parkY(at:x,width:w,layout:l,sites:last)>site.groundBounds.maxY+l.routeOffset-l.height+15.5*s,"Park cuts a complete building footing")
    }
   }
   for d in [tunnel.rampStart,tunnel.rampEnd] {
    checks += 2
    precondition(abs(tunnel.wallTop(at:d)-19.5)<0.00001,"Wall begins outside continuous coping")
    precondition(abs(tunnel.wallFoot(at:d)-19.5)<0.00001,"Wall begins with a transverse step")
    let epsilon=0.2*s
    let a=tunnel.floorPoint(at:d-epsilon),b=tunnel.floorPoint(at:d),c=tunnel.floorPoint(at:d+epsilon)
    checks += 1;precondition(hypot((c.x-b.x)-(b.x-a.x),(c.y-b.y)-(b.y-a.y))<0.015*s,"Track tangent breaks at ramp")
    let bed=tunnel.railRibbon(halfWidth:19.5)
    for delta:CGFloat in [-3,-1,1,3] {
     for lateral:CGFloat in [-18,0,18] {
      checks += 1;precondition(bed.contains(tunnel.point(d+delta*s,lateral:lateral)),"Rail bed opens at ramp seam")
     }
    }
   }
   checks += 1;precondition(tunnel.arch(at:tunnel.start,radius:29,crown:73).boundingRect.maxX<12*s,"Left portal protrudes past its outer frontage")
   checks += 1;precondition(tunnel.arch(at:tunnel.end,radius:29,crown:73).boundingRect.minX>w,"Right portal returned into view")
   print("PORTAL \(Int(w)) \(tunnel.floorPoint(at:tunnel.start)) FRONTAGE \(sites.first{$0.id == 25000}!)")
   print("\(Int(w))pt: \(sites.count) city plots, \(arrival.count) cave frontages, \(last.count) park frontages; continuous ramp profiles and complete footings")
  }
  print("PASS: \(checks) city geometry checks")
 }
}
