import AppKit
import CoreGraphics
import CoreImage

final class BlurAnnotation: Annotation {
    let id = UUID()
    var strokeColor: NSColor
    var strokeWidth: CGFloat
    var origin: CGPoint
    var end: CGPoint
    var blurRadius: Double

    // Cached blur result
    private var cachedBlur: CGImage?
    private var cachedRect: CGRect = .zero

    init(origin: CGPoint, end: CGPoint, strokeColor: NSColor = .clear,
         strokeWidth: CGFloat = 0, blurRadius: Double = Constants.defaultBlurRadius) {
        self.origin = origin
        self.end = end
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.blurRadius = blurRadius
    }

    var rect: CGRect {
        GeometryHelpers.normalizedRect(from: origin, to: end)
    }

    func draw(in context: CGContext, scale: CGFloat) {
        let r = rect
        guard r.width > 1, r.height > 1 else { return }

        // Pixelate effect (faster than Gaussian blur and looks good)
        context.saveGState()
        context.clip(to: r)

        // Get the image data under the rect and draw it pixelated
        if let existingImage = context.makeImage() {
            let pixelRect = CGRect(
                x: r.origin.x * scale,
                y: r.origin.y * scale,
                width: r.width * scale,
                height: r.height * scale
            )
            if let cropped = existingImage.cropping(to: pixelRect) {
                let ciImage = CIImage(cgImage: cropped)
                let filter = CIFilter(name: "CIPixellate")!
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                filter.setValue(max(r.width, r.height) / 15, forKey: kCIInputScaleKey)
                let ciContext = CIContext(options: [.useSoftwareRenderer: false])
                if let output = filter.outputImage,
                   let blurred = ciContext.createCGImage(output, from: ciImage.extent) {
                    context.draw(blurred, in: r)
                }
            }
        }

        // Fallback: draw semi-transparent fill
        context.setFillColor(NSColor.gray.withAlphaComponent(0.4).cgColor)
        context.fill(r)

        context.restoreGState()

        // Draw subtle border to show the blur region
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(0.5)
        context.setLineDash(phase: 0, lengths: [3, 3])
        context.stroke(r)
        context.setLineDash(phase: 0, lengths: [])
    }

    func hitTest(point: CGPoint) -> Bool {
        rect.insetBy(dx: -4, dy: -4).contains(point)
    }

    func boundingRect() -> CGRect {
        rect
    }

    func copy() -> Annotation {
        BlurAnnotation(origin: origin, end: end, strokeColor: strokeColor,
                       strokeWidth: strokeWidth, blurRadius: blurRadius)
    }
}
