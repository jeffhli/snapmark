import AppKit
import CoreGraphics
import UniformTypeIdentifiers

enum ImageExporter {
    static func renderImage(baseImage: NSImage, annotations: [Annotation]) -> NSImage? {
        guard let cgBase = baseImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let pixelWidth = cgBase.width
        let pixelHeight = cgBase.height
        let viewWidth = baseImage.size.width
        let viewHeight = baseImage.size.height
        let scaleX = CGFloat(pixelWidth) / viewWidth
        let scaleY = CGFloat(pixelHeight) / viewHeight
        let scale = max(scaleX, scaleY)

        guard let context = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // Flip coordinate system for drawing the base image (CG images need top-left origin)
        context.saveGState()
        context.translateBy(x: 0, y: CGFloat(pixelHeight))
        context.scaleBy(x: 1, y: -1)

        // Draw base image
        let imageRect = CGRect(x: 0, y: 0, width: CGFloat(pixelWidth), height: CGFloat(pixelHeight))
        context.draw(cgBase, in: imageRect)
        context.restoreGState()

        // Draw annotations in non-flipped context (matching the canvas coordinate system)
        // Scale context for annotations (they use view coordinates)
        context.scaleBy(x: scale, y: scale)

        // Draw annotations
        for annotation in annotations {
            context.saveGState()
            annotation.draw(in: context, scale: scale)
            context.restoreGState()
        }

        guard let resultCG = context.makeImage() else { return nil }
        return NSImage(cgImage: resultCG, size: NSSize(width: viewWidth, height: viewHeight))
    }

    static func pngData(from image: NSImage) -> Data? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        rep.size = image.size
        return rep.representation(using: .png, properties: [:])
    }

    static func copyToClipboard(image: NSImage, annotations: [Annotation]) {
        guard let rendered = renderImage(baseImage: image, annotations: annotations) else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([rendered])
    }
}
