from pathlib import Path
import sys
root=Path(__file__).resolve().parents[3]
ui=(root/'Dino/Views/DinoUI.swift').read_text()
env=ui[ui.index('private struct DinoMapPreparingKey'):ui.index('/// A paused TimelineView')]
world=(root/'Dino/Core/LevelConfiguration.swift').read_text()
world=world[world.index('struct DinoWorld:'):world.index('/// A fixed teaching route.')]
support='''import SwiftUI
import AppKit
@propertyWrapper final class AuditState<Value> { var wrappedValue: Value; init(wrappedValue:Value) {self.wrappedValue=wrappedValue}; var projectedValue: Binding<Value> { .constant(wrappedValue) } }
extension Color { func mixed(with other:Color,by fraction:Double)->Color {mix(with:other,by:fraction)} }
extension Text { func canvasInk(_ color:Color)->Text { self.foregroundColor(color) } }
extension Color { init(dinoHex: UInt32) { self.init(red:Double((dinoHex>>16)&255)/255,green:Double((dinoHex>>8)&255)/255,blue:Double(dinoHex&255)/255) } }
struct PreparedMapArtwork<Content: View>: View { let worldID: Int; let size: CGSize; let routeOffset: CGFloat; let ground: UInt32?; var tileContent: ((CGRect)->Content)? = nil; @ViewBuilder var content: ()->Content; var body: some View { content() } }
struct MapAnimationVisibility: ViewModifier { let viewportHeight: CGFloat; var alwaysVisible=false; func body(content:Content)->some View {content} }
extension View { func readGeometry<T: Equatable>(for type:T.Type,of transform:@escaping (GeometryProxy)->T,action:@escaping (T)->Void)->some View { self } }
enum DigitalHourNotation: String { case twelve,twentyFour }
'''+env+world+'\nfunc L(key:String)->String { DinoWorldCatalog.worlds.first { $0.titleKey == key }.map { ["Jungle","Woestijn","Vulkaan","Klokdorp","Kristalgrot","Klokstad","Slaapvallei","Tijdmachine","Tijdpiraten","Kasteel"][$0.id-1] } ?? key }\n'
files=['Dino/Core/ClockTime.swift','Dino/Core/DinoAnimation.swift','Dino/Core/JungleMapLayout.swift','Dino/Views/WorldBossArt.swift','Dino/Views/DinoDesert.swift','Dino/Views/JungleLandscape.swift']
s=support+'\n'+'\n'.join((root/f).read_text().replace('@State ','@AuditState ') for f in files)
s=s.replace('import UIKit', '')
s=s.replace('let base = UIFont.systemFont(ofSize: 39, weight: .black)', 'let base = NSFont.systemFont(ofSize: 39, weight: .black)').replace('UIFontDescriptor.SystemDesign', 'NSFontDescriptor.SystemDesign').replace('UIFont(descriptor:', 'NSFont(descriptor:').replace('withDesign(face).map { NSFont', 'withDesign(face).flatMap { NSFont')
s=s.replace('Text("dino.worldNumber \\(world.id)")','Text("WERELD \\(world.id)")').replace('Text(LocalizedStringKey(world.titleKey))','Text(["Jungle","Woestijn","Vulkaan","Klokdorp","Kristalgrot","Klokstad","Slaapvallei","Tijdmachine","Tijdpiraten","Kasteel"][world.id-1])').replace('Text(LocalizedStringKey(world.skillKey))','Text("Klokavontuur")')
assets=(root/'Dino/Core/DinoAvatarMask.swift').read_text()
start=assets.index('enum DinoAnswerArtwork')
s+='\n'+assets[start:assets.index('\n}\n',start)+3]
output=Path(sys.argv[1]);output.mkdir(parents=True,exist_ok=True)
(output/'native.swift').write_text(s+'\n'+Path(__file__).with_name('render-main.swift').read_text())
