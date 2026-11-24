import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Fixed-grid import, not automatic per-cell fitting. Source PNGs remain archived
// outside the catalog. Only preparation cleans generated alpha; runtime recolors
// preserve every resulting alpha byte. Coordinates here are top-left source pixels.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
func load(_ path: String) -> CGImage {
    CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(URL(fileURLWithPath:path) as CFURL,nil)!,0,nil)!
}
func write(_ image: CGImage, _ path: String) {
    let url = URL(fileURLWithPath:path)
    try! FileManager.default.createDirectory(at:url.deletingLastPathComponent(),withIntermediateDirectories:true)
    let dst = CGImageDestinationCreateWithURL(url as CFURL,UTType.png.identifier as CFString,1,nil)!
    CGImageDestinationAddImage(dst,image,nil); precondition(CGImageDestinationFinalize(dst))
}
func clean(_ source: CGImage) -> CGImage {
    let w=source.width,h=source.height, format=CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
    var data=[UInt8](repeating:0,count:w*h*4)
    data.withUnsafeMutableBytes { b in
        let c=CGContext(data:b.baseAddress,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:format)!
        c.draw(source,in:CGRect(x:0,y:0,width:w,height:h))
        let p=b.bindMemory(to:UInt8.self)
        // The tool emits near-opaque interiors (~253) and tiny colored alpha
        // islands. Retain the dominant connected silhouette; normalize its
        // interior to opaque without washing out premultiplied edge colors.
        var seen=[Bool](repeating:false,count:w*h), largest=[Int]()
        for start in 0..<w*h where !seen[start] && p[start*4+3] >= 128 {
            var q=[start],i=0; seen[start]=true
            while i<q.count {
                let n=q[i]; i+=1
                for m in [n%w>0 ? n-1 : -1,n%w<w-1 ? n+1 : -1,n>=w ? n-w : -1,n<w*(h-1) ? n+w : -1] where m>=0 {
                    if !seen[m] && p[m*4+3]>=128 {seen[m]=true;q.append(m)}
                }
            }
            if q.count>largest.count {largest=q}
        }
        var keep=[Bool](repeating:false,count:w*h)
        for n in largest {keep[n]=true}
        // One-pixel antialias skirt attached to the actual silhouette only.
        for n in largest {
            for m in [n%w>0 ? n-1 : -1,n%w<w-1 ? n+1 : -1,n>=w ? n-w : -1,n<w*(h-1) ? n+w : -1] where m>=0 && p[m*4+3]>=32 {keep[m]=true}
        }
        // Repair only tiny enclosed alpha defects, never the open negative
        // spaces between arms, horns and tail. Keep the real antialias boundary.
        var visited=[Bool](repeating:false,count:w*h)
        for start in 0..<w*h where !keep[start] && !visited[start] {
            var q=[start],j=0,touchesEdge=false;visited[start]=true
            while j<q.count {let n=q[j];j+=1
                if n%w==0 || n%w==w-1 || n<w || n>=w*(h-1) {touchesEdge=true}
                for m in [n%w>0 ? n-1:-1,n%w<w-1 ? n+1:-1,n>=w ? n-w:-1,n<w*(h-1) ? n+w:-1] where m>=0 {
                    if !keep[m] && !visited[m] {visited[m]=true;q.append(m)}
                }
            }
            if !touchesEdge && q.count<=16 {for n in q {keep[n]=true}}
        }
        var deep=keep
        for _ in 0..<3 {
            let before=deep
            for y in 1..<(h-1) {for x in 1..<(w-1) {let n=y*w+x;deep[n]=before[n] && before[n-1] && before[n+1] && before[n-w] && before[n+w]}}
        }
        let original=Array(p)
        for n in 0..<w*h {
            let i=n*4,a=Double(original[i+3])
            guard keep[n],a>=32 || deep[n] else {for k in 0..<4 {p[i+k]=0};continue}
            let alpha = deep[n] ? 255.0 : min(255,max(0,(a-32)*255/208))
            for k in 0..<3 {
                var value=Double(original[i+k])/max(1,a)
                if a<32 {
                    var sum=0.0,weight=0.0
                    for yy in max(0,n/w-2)...min(h-1,n/w+2) {for xx in max(0,n%w-2)...min(w-1,n%w+2) {
                        let j=(yy*w+xx)*4,otherAlpha=Double(original[j+3])
                        if otherAlpha>128 {sum+=Double(original[j+k])/otherAlpha;weight+=1}
                    }}
                    value=sum/max(1,weight)
                }
                p[i+k]=UInt8(min(alpha,(value*alpha).rounded()))
            }
            p[i+3]=UInt8(alpha.rounded())
        }
    }
    let provider=CGDataProvider(data:Data(data) as CFData)!
    return CGImage(width:w,height:h,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:w*4,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGBitmapInfo(rawValue:format),provider:provider,decode:nil,shouldInterpolate:true,intent:.defaultIntent)!
}
func cell(_ image: CGImage, _ index: Int) -> CGImage {
    let x=index%4,y=index/4
    let l=Int((Double(x)*Double(image.width)/4).rounded()),r=Int((Double(x+1)*Double(image.width)/4).rounded())
    let t=Int((Double(y)*Double(image.height)/2).rounded()),b=Int((Double(y+1)*Double(image.height)/2).rounded())
    return image.cropping(to:CGRect(x:l,y:t,width:r-l,height:b-t))!
}
func export(_ source: CGImage, _ name: String, side: Int=512, dx: Double=0, dy: Double=0, scale: Double=1) {
    let image=clean(source)
    let c=CGContext(data:nil,width:side,height:side,bitsPerComponent:8,bytesPerRow:side*4,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.interpolationQuality = .high
    // CoreGraphics drawing y runs upwards. dy is a top-left normalized offset.
    c.draw(image,in:CGRect(x:dx*Double(side),y:(1-scale-dy)*Double(side),width:Double(side)*scale,height:Double(side)*scale))
    let dir="Assets.xcassets/\(name).imageset"
    write(c.makeImage()!,"\(dir)/\(name).png")
    let manifest="{\"images\":[{\"filename\":\"\(name).png\",\"idiom\":\"universal\"}],\"info\":{\"author\":\"xcode\",\"version\":1}}\n"
    try! manifest.write(toFile:"\(dir)/Contents.json",atomically:true,encoding:.utf8)
}
func recoveryCell(_ image:CGImage,_ index:Int)->CGImage {
    let left=Int((Double(index)*Double(image.width)/2).rounded()),right=Int((Double(index+1)*Double(image.width)/2).rounded())
    return image.cropping(to:CGRect(x:left,y:0,width:right-left,height:image.height))!
}
let args=CommandLine.arguments
if args.count==3 && args[1]=="--recovery-only" {
    let sheet=load(args[2])
    export(recoveryCell(sheet,0),"volcano-rise-low",dx:0.02,dy:0.04390625,scale:0.96)
    export(recoveryCell(sheet,1),"volcano-rise-high",dx:0.02,dy:0.05171875,scale:0.96)
    exit(0)
}
precondition(args.count==5,"Usage: canonical reactions motion turn")
let canonical=load(args[1]),reactions=load(args[2]),motion=load(args[3]),turn=load(args[4])
export(canonical,"volcano-opening-idle",side:1254,dx:0.02,dy:0.04,scale:0.96)
export(canonical,"volcano-idle",dx:0.02,dy:0.04,scale:0.96)
let names=["unused","volcano-wrong","volcano-clap-open","volcano-clap-contact","volcano-clap-open-2","volcano-clap-contact-2","volcano-crouch","volcano-landing"]
for i in 1..<8 {export(cell(reactions,i),names[i],dx:0.02,dy:0.02,scale:0.96)}
for (i,name) in ["volcano-takeoff","volcano-airborne","volcano-stumble","volcano-fallen","volcano-push-up"].enumerated() {export(cell(motion,i),name,dx:0.02,dy:0.02,scale:0.96)}
for i in 0..<8 {export(cell(turn,i),String(format:"volcano-turn-%02d",i+1),dx:0.02,dy:0.02,scale:0.96)}
print("Imported detailed 1254px opening and fixed-grid 512px Magma sprites")
