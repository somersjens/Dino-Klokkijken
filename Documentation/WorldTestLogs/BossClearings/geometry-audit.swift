// Run inside the native landscape audit module, alongside the app painters.
  var checks = 0
  func check(_ condition: Bool, _ message: String) { precondition(condition, message); checks += 1 }
  for w:CGFloat in [320,375,390,393,430,507,600,744,834,1024,1194,1366] {
   let layout=WorldSceneryLayout(width:w,height:WorldMapChapterSpacing.sceneSize(width:w).height,routeOffset:WorldMapChapterSpacing.sceneOffset(width:w))
   let s=layout.scale
   let castle=CastleWaterPlan.cached(scenery:layout)
   let field=TimeMachineLayout.waterField(layout:layout)
   for id in [3,4,5,8,10] {
    let stage=WorldBossStage(worldID:id,width:w)
    let body=WorldBossPainter.bounds(worldID:id,at:stage.point,size:s*0.88)
    check(body.minX>0 && body.maxX<w,"body cropped: \(id) at \(w)")
    check(stage.clearance.contains(body),"body outside reservation: \(id) at \(w)")
    for right in [false,true] {
     let water:Path
     if id==3 { water=VolcanoWorldLayout.channel(layout:layout,right:right,from:1400,to:1800).strokedPath(.init(lineWidth:VolcanoWorldLayout.channelRockWidth(scale:s,width:w))) }
     else if id==4 { water=layout.villageCanalPath(right:right).strokedPath(.init(lineWidth:66*s)) }
     else if id==8 { water=field.currents[right ? 1:0].strokedPath(.init(lineWidth:30*s)) }
     else if id==10 { water=castle.layout.waterway(right:right).strokedPath(.init(lineWidth:78*s)) }
     else { water=Path() }
     for x in stride(from:stage.ground.minX,through:stage.ground.maxX,by:3) {
      for y in stride(from:stage.ground.minY,through:stage.ground.maxY,by:3) {
       check(!water.contains(.init(x:x,y:y)),"wet floor: \(id) at \(w), \(x),\(y)")
       if id==5 {
        let edge=CrystalCaveLifeLayout.wallX(at:y+layout.routeOffset,right:true,distance:127,layout:layout)
        check(x<edge,"cave feet in wall: \(w)")
       }
      }
     }
    }
   }
   let volcano=WorldBossStage(worldID:3,width:w)
   check(VolcanoWorldLayout.sources(layout:layout).allSatisfy { !$0.terrainBands.contains { $0.intersects(volcano.clearance) } },"volcano cone occludes boss: \(w)")
   check(VolcanoWorldLayout.looseRocks(layout:layout).allSatisfy { !$0.bounds.intersects(volcano.clearance) },"volcano rubble occludes boss: \(w)")
   check(VolcanoWorldLayout.terrainSlabs(layout:layout).allSatisfy { !$0.bounds.intersects(volcano.clearance) },"volcano slabs under boss: \(w)")
   let rail=CityMetroLine(layout:layout),city=CityBossCourt(layout:layout,line:rail)
   check(rail.groundIsClear(city.groundBounds,scale:s),"city floor on railway: \(w)")
   check(CityUrbanLayout.sites(layout:layout).allSatisfy { !$0.contentBounds.intersects(city.clearance) },"city facade occludes boss: \(w)")
   let stage=WorldBossStage(worldID:8,width:w)
   check(TimeMachineLayout.sites(layout:layout).allSatisfy { !$0.bodyBounds.intersects(stage.clearance) },"machine occludes boss: \(w)")
   check(TimeMachineLayout.furnishings(layout:layout).allSatisfy { !$0.bounds.intersects(stage.clearance) },"apparatus occludes boss: \(w)")
   check(field.lanterns.allSatisfy { !$0.bounds.intersects(stage.clearance) },"lantern occludes boss: \(w)")
   check(field.bridges.allSatisfy { !$0.bounds.intersects(stage.clearance) },"bridge occludes boss: \(w)")
   check(field.terminals.allSatisfy { !$0.drainBounds.intersects(stage.ground) },"drain under boss: \(w)")
  }
  print("Geometry: \(checks) checks passed on twelve widths")
