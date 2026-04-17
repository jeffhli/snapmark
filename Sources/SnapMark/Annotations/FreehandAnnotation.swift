import AppKit
import CoreGraphics

final class FreehandAnnotation: Annotation {
    let id = UUID()
    var strokeColor: NSColor
    var strokeWidth: CGFloat
    var points: [CGPoint] = []

    init(strokeColor: NSColor = Constants.defaultStrokeColor,
         strokeWidth: CGFloat = Constants.defaultStrokeWidth) {
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
    }

    func addPoint(_ point: CGPoint) {
        points.append(point)
    }

    func draw(in context: CGContext, scale: CGFloat) {
        guard points.count >= 2 else { return }

        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(strokeWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        context.move(to: points[0])
        for i in 1..<points.count {
            context.addLine(to: points[i])
        }
        context.strokePath()
    }

    func hitTest(point: CGPoint) -> Bool {
        for i in 1..<points.count {
            if GeometryHelpers.pointNearLine(point: point, lineStart: points[i - 1],
                                             lineEnd: points[i], threshold: strokeWidth + 4) {
                return true
            }
        }
        return false
    }

    func boundingRect() -> CGRect {
        guard !points.isEmpty else { return .zero }
        var minX = CGFloat.infinity, minY = CGFloat.infinity
        var maxX = -CGFloat.infinity, maxY = -CGFloat.infinity
        for p in points {
            minX = min(minX, p.x)
            minY = min(minY, p.y)
            maxX = max(maxX, p.x)
            maxY = max(maxY, p.y)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
            .insetBy(dx: -(strokeWidth + 2), dy: -(strokeWidth + 2))
    }

    func copy() -> Annotation {
        let a = FreehandAnnotation(strokeColor: strokeColor, strokeWidth: strokeWidth)
        a.points = points
        return a
    }
}
