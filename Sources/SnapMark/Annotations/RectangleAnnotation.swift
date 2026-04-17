import AppKit
import CoreGraphics

final class RectangleAnnotation: Annotation {
    let id = UUID()
    var strokeColor: NSColor
    var strokeWidth: CGFloat
    var origin: CGPoint
    var end: CGPoint
    var fillColor: NSColor?

    init(origin: CGPoint, end: CGPoint, strokeColor: NSColor = Constants.defaultStrokeColor,
         strokeWidth: CGFloat = Constants.defaultStrokeWidth, fillColor: NSColor? = nil) {
        self.origin = origin
        self.end = end
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.fillColor = fillColor
    }

    var rect: CGRect {
        GeometryHelpers.normalizedRect(from: origin, to: end)
    }

    func draw(in context: CGContext, scale: CGFloat) {
        let r = rect
        if let fill = fillColor {
            context.setFillColor(fill.cgColor)
            context.fill(r)
        }
        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(strokeWidth)
        context.stroke(r)
    }

    func hitTest(point: CGPoint) -> Bool {
        let r = GeometryHelpers.expanded(rect, by: strokeWidth + 4)
        return r.contains(point)
    }

    func boundingRect() -> CGRect {
        GeometryHelpers.expanded(rect, by: strokeWidth)
    }

    func copy() -> Annotation {
        RectangleAnnotation(origin: origin, end: end, strokeColor: strokeColor,
                            strokeWidth: strokeWidth, fillColor: fillColor)
    }
}
