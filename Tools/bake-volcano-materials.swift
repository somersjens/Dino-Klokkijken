import Foundation
import CoreGraphics
import ImageIO
@MainActor final class DinoAnswerFeedback {static let shared=DinoAnswerFeedback();nonisolated func setSoundEnabled(_ v:Bool){}}
@main struct BakeMagma {
 static func main() throws {
  let checking=CommandLine.arguments.contains("--check")
  var measurements=[String:Any]()
  var data=Data([77,71,77,57])
  func u16(_ n:Int){data.append(UInt8(n&255));data.append(UInt8((n>>8)&255))}
  func u32(_ n:Int){for shift in [0,8,16,24]{data.append(UInt8((n>>shift)&255))}}
  let assets=DinoVolcanoArtwork.assets.sorted()+[DinoVolcanoArtwork.openingAsset];u16(assets.count)
  for asset in assets {
   let url=URL(fileURLWithPath:"Assets.xcassets/\(asset).imageset/\(asset).png")
   let source=CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL,nil)!,0,nil)!
   let labels=DinoSpriteColorRenderer.volcanoLabels(source,asset:asset,useArchive:false)
   if checking {precondition(labels == DinoSpriteColorRenderer.volcanoLabels(source,asset:asset),"Stale material archive: \(asset)")}
   let rig=DinoSpriteColorRenderer.VolcanoRig(asset:asset),t=rig.headTransform
   func rect(_ r:CGRect)->[Double] {[r.minX,r.minY,r.width,r.height]}
   measurements[asset] = ["clockBounds512":rig.clocks.map(rect),"handExclusions512":rig.hands.map(rect),"headBounds512":rect(rig.head.boundingBoxOfPath),"headTransform512":[t.a,t.b,t.c,t.d,t.tx,t.ty]]
   var runs=[(Int,UInt8)](),start=0
   while start<labels.count {let label=labels[start];var end=start+1;while end<labels.count && labels[end]==label {end+=1};runs.append((end-start,label));start=end}
   let name=Data(asset.utf8);u16(name.count);u16(source.width);u16(source.height);u32(runs.count);data.append(name)
   for (count,label) in runs {u32(count);data.append(label)}
  }
  try JSONSerialization.data(withJSONObject:measurements,options:[.prettyPrinted,.sortedKeys]).write(to:URL(fileURLWithPath:"/tmp/magma-rig-measurements.json"))
  if checking {print("Validated all \(assets.count) archived source mattes against fresh geometry");return}
  let folder=URL(fileURLWithPath:"Assets.xcassets/volcano-materials.dataset",isDirectory:true)
  try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
  try data.write(to:folder.appendingPathComponent("magma-materials.bin"))
  try Data("{\"data\":[{\"filename\":\"magma-materials.bin\",\"idiom\":\"universal\"}],\"info\":{\"author\":\"xcode\",\"version\":1}}\n".utf8).write(to:folder.appendingPathComponent("Contents.json"))
  print("Baked \(assets.count) source mattes: \(data.count) bytes")
 }
}
