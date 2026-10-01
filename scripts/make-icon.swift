import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let dimension = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard CommandLine.arguments.count == 2,
      let context = CGContext(data: nil, width: dimension, height: dimension, bitsPerComponent: 8,
          bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    fatalError("Cannot create icon")
}
context.setFillColor(CGColor(red: 0.05, green: 0.38, blue: 0.90, alpha: 1))
context.addPath(CGPath(roundedRect: CGRect(x: 72, y: 72, width: 880, height: 880), cornerWidth: 190, cornerHeight: 190, transform: nil))
context.fillPath()
context.setStrokeColor(CGColor(gray: 1, alpha: 1))
context.setLineWidth(44)
context.setLineCap(.round)
context.setLineJoin(.round)
for (x, y, dx, dy) in [(280.0, 310.0, 1.0, 1.0), (744, 310, -1, 1), (280, 714, 1, -1), (744, 714, -1, -1)] {
    context.move(to: CGPoint(x: x, y: y + 88 * dy))
    context.addLine(to: CGPoint(x: x, y: y))
    context.addLine(to: CGPoint(x: x + 88 * dx, y: y))
    context.strokePath()
}
context.strokeEllipse(in: CGRect(x: 410, y: 410, width: 204, height: 204))
guard let image = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL,
          UTType.png.identifier as CFString, 1, nil) else { fatalError("Cannot write icon") }
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("Cannot finalize icon") }
