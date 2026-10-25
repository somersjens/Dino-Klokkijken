private struct ChapterAudit: View {
 let worldID:Int; let width:CGFloat
 var size:CGSize { var result=WorldMapChapterSpacing.sceneSize(width:width); if worldID == 1 { result.height=offset+JungleMapLayout.firstNodeY+9*JungleMapLayout.levelSpacing+JungleMapLayout.bossReturnSpan(for:width) }; return result }
 var offset:CGFloat { WorldMapChapterSpacing.sceneOffset(width:width) }
 var body:some View {
  ZStack(alignment:.topLeading) {
   if worldID == 1 { WorldMapLandscape(routeOffset:offset,viewportHeight:2500,cachesTerrain:true) }
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
@main struct RenderJoins {
 @MainActor static func main() throws {
  let dir=URL(fileURLWithPath:CommandLine.arguments[1]);try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
  let widths:[CGFloat]=CommandLine.arguments.count>2 ? [CGFloat(Double(CommandLine.arguments[2])!)]:[320,393,834,1194]
  for w in widths {
   for n in [5,6] {
    let h=WorldMapChapterSpacing.sceneSize(width:w).height - (n == 1 ? 10:0)
    let view=VStack(spacing:0) {ChapterAudit(worldID:n,width:w);ChapterAudit(worldID:n+1,width:w)}.offset(y:-(h-350)).frame(width:w,height:920,alignment:.top).clipped()
    let renderer=ImageRenderer(content:view);renderer.scale=1
    if let cg=renderer.cgImage {try NSBitmapImageRep(cgImage:cg).representation(using:.png,properties:[:])!.write(to:dir.appendingPathComponent("join-\(n)-\(Int(w)).png"))}
   }
   for n in [6] {
    let renderer=ImageRenderer(content:ChapterAudit(worldID:n,width:w));renderer.scale=1
    if let cg=renderer.cgImage {try NSBitmapImageRep(cgImage:cg).representation(using:.png,properties:[:])!.write(to:dir.appendingPathComponent("world-\(n)-\(Int(w)).png"))}
   }
   let l=WorldSceneryLayout(width:w,height:WorldMapChapterSpacing.sceneSize(width:w).height,routeOffset:WorldMapChapterSpacing.sceneOffset(width:w))
   let tunnel=CityMetroTunnel(line:CityMetroLine(layout:l),scale:l.scale)
   for site in CityUrbanLayout.sites(layout:l) where site.id >= 25000 || (site.point.y < 250 && !site.arrival) { print("SITE \(site)") }
   print("RAMP \(Int(w)) \(tunnel.floorPoint(at:tunnel.rampStart))")
   print("Rendered \(Int(w))pt; added city buildings: \(CityUrbanLayout.sites(layout:l).count)")
  }
 }
}
