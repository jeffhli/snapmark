import AppKit

enum GeometryHelpers {
    /// Normalize a rect so width and height are positive
    static func normalizedRect(from p1: CGPoint, to p2: CGPoint) -> CGRect {
        let x = min(p1.x, p2.x)
        let y = min(p1.y, p2.y)
        let w = abs(p2.x - p1.x)
        let h = abs(p2.y - p1.y)
        return CGRect(x: x, y: y, width: w, height: h)
    }

    /// Distance between two points
    static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = b.x - a.x
        let dy = b.y - a.y
        return sqrt(dx * dx + dy * dy)
    }

    /// Angle from point a to point b in radians
    static func angle(from a: CGPoint, to b: CGPoint) -> CGFloat {
        return atan2(b.y - a.y, b.x - a.x)
    }

    /// Expand rect by a margin
    static func expanded(_ rect: CGRect, by margin: CGFloat) -> CGRect {
        return rect.insetBy(dx: -margin, dy: -margin)
    }

    /// Check if a point is near a line segment
    static func pointNearLine(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint, threshold: CGFloat) -> Bool {
        let d = distance(lineStart, lineEnd)
        guard d > 0 else { return distance(point, lineStart) <= threshold }
        let t = max(0, min(1, ((point.x - lineStart.x) * (lineEnd.x - lineStart.x) +
            (point.y - lineStart.y) * (lineEnd.y - lineStart.y)) / (d * d)))
        let proj = CGPoint(x: lineStart.x + t * (lineEnd.x - lineStart.x),
                           y: lineStart.y + t * (lineEnd.y - lineStart.y))
        return distance(point, proj) <= threshold
    }
}
