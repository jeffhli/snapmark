import AppKit
import CoreGraphics

final class HighlightAnnotation: Annotation {
    let id = UUID()
    var strokeColor: NSColor
    var strokeWidth: CGFloat
    var origin: CGPoint
    var end: CGPoint

    init(origin: CGPoint, end: CGPoint, strokeColor: NSColor = .systemYellow,
         strokeWidth: CGFloat = Constants.defaultStrokeWidth) {
        self.origin = origin
        self.end = end
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
    }

    var rect: CGRect {
        GeometryHelpers.normalizedRect(from: origin, to: end)
    }

    func draw(in context: CGContext, scale: CGFloat) {
        let r = rect
        context.saveGState()
        context.setBlendMode(.multiply)
        context.setFillColor(strokeColor.withAlphaComponent(0.35).cgColor)
        context.fill(r)
        context.restoreGState()
    }

    func hitTest(point: CGPoint) -> Bool {
        rect.insetBy(dx: -4, dy: -4).contains(point)
    }

    func boundingRect() -> CGRect {
        rect
    }

    func copy() -> Annotation {
        HighlightAnnotation(origin: origin, end: end, strokeColor: strokeColor, strokeWidth: strokeWidth)
    }
}
