import AppKit
import CoreGraphics

final class ArrowAnnotation: Annotation {
    let id = UUID()
    var strokeColor: NSColor
    var strokeWidth: CGFloat
    var startPoint: CGPoint
    var endPoint: CGPoint
    private let headLength: CGFloat = 16
    private let headAngle: CGFloat = .pi / 6

    init(start: CGPoint, end: CGPoint, strokeColor: NSColor = Constants.defaultStrokeColor,
         strokeWidth: CGFloat = Constants.defaultStrokeWidth) {
        self.startPoint = start
        self.endPoint = end
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
    }

    func draw(in context: CGContext, scale: CGFloat) {
        let angle = GeometryHelpers.angle(from: startPoint, to: endPoint)
        let scaledHead = headLength + strokeWidth * 2

        // Draw line
        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(strokeWidth)
        context.setLineCap(.round)
        context.move(to: startPoint)
        context.addLine(to: endPoint)
        context.strokePath()

        // Draw arrowhead
        let p1 = CGPoint(
            x: endPoint.x - scaledHead * cos(angle - headAngle),
            y: endPoint.y - scaledHead * sin(angle - headAngle)
        )
        let p2 = CGPoint(
            x: endPoint.x - scaledHead * cos(angle + headAngle),
            y: endPoint.y - scaledHead * sin(angle + headAngle)
        )

        context.setFillColor(strokeColor.cgColor)
        context.move(to: endPoint)
        context.addLine(to: p1)
        context.addLine(to: p2)
        context.closePath()
        context.fillPath()
    }

    func hitTest(point: CGPoint) -> Bool {
        GeometryHelpers.pointNearLine(point: point, lineStart: startPoint,
                                      lineEnd: endPoint, threshold: strokeWidth + 6)
    }

    func boundingRect() -> CGRect {
        let r = GeometryHelpers.normalizedRect(from: startPoint, to: endPoint)
        return GeometryHelpers.expanded(r, by: headLength + strokeWidth)
    }

    func copy() -> Annotation {
        ArrowAnnotation(start: startPoint, end: endPoint, strokeColor: strokeColor, strokeWidth: strokeWidth)
    }
}
