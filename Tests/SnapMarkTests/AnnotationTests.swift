import AppKit
@testable import SnapMarkLib

// Helper: create a CGContext for draw tests
func makeContext(width: Int = 100, height: Int = 100) -> CGContext {
    CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
}

func runAnnotationTests() {

    // ─── RectangleAnnotation ───

    suite("RectangleAnnotation")

    test("init sets properties") {
        let a = RectangleAnnotation(origin: CGPoint(x: 10, y: 20), end: CGPoint(x: 50, y: 60), strokeColor: .red, strokeWidth: 3)
        try expectApprox(a.origin.x, 10); try expectApprox(a.origin.y, 20)
        try expectApprox(a.end.x, 50); try expectApprox(a.end.y, 60)
        try expect(a.fillColor == nil)
    }

    test("rect normalizes") {
        let a = RectangleAnnotation(origin: CGPoint(x: 50, y: 60), end: CGPoint(x: 10, y: 20))
        try expectApprox(a.rect.origin.x, 10); try expectApprox(a.rect.width, 40)
    }

    test("hitTest inside") {
        let a = RectangleAnnotation(origin: CGPoint(x: 10, y: 10), end: CGPoint(x: 50, y: 50))
        try expect(a.hitTest(point: CGPoint(x: 30, y: 30)))
    }

    test("hitTest outside") {
        let a = RectangleAnnotation(origin: CGPoint(x: 10, y: 10), end: CGPoint(x: 50, y: 50))
        try expect(!a.hitTest(point: CGPoint(x: 200, y: 200)))
    }

    test("boundingRect includes stroke") {
        let a = RectangleAnnotation(origin: CGPoint(x: 10, y: 10), end: CGPoint(x: 50, y: 50), strokeWidth: 4)
        let br = a.boundingRect()
        try expect(br.origin.x < 10); try expect(br.maxX > 50)
    }

    test("copy is independent") {
        let a = RectangleAnnotation(origin: CGPoint(x: 10, y: 20), end: CGPoint(x: 50, y: 60), strokeColor: .blue, strokeWidth: 5)
        let b = a.copy() as! RectangleAnnotation
        try expect(b.id != a.id)
        try expectApprox(b.origin.x, 10)
        b.origin = CGPoint(x: 999, y: 999)
        try expectApprox(a.origin.x, 10)
    }

    test("unique IDs") {
        let a = RectangleAnnotation(origin: .zero, end: CGPoint(x: 10, y: 10))
        let b = RectangleAnnotation(origin: .zero, end: CGPoint(x: 10, y: 10))
        try expect(a.id != b.id)
    }

    test("draw does not crash") {
        let a = RectangleAnnotation(origin: CGPoint(x: 5, y: 5), end: CGPoint(x: 50, y: 50))
        a.draw(in: makeContext(), scale: 1.0)
    }

    test("draw with fill does not crash") {
        let a = RectangleAnnotation(origin: CGPoint(x: 5, y: 5), end: CGPoint(x: 50, y: 50), fillColor: .yellow)
        a.draw(in: makeContext(), scale: 2.0)
    }

    // ─── ArrowAnnotation ───

    suite("ArrowAnnotation")

    test("init sets properties") {
        let a = ArrowAnnotation(start: CGPoint(x: 10, y: 10), end: CGPoint(x: 100, y: 100), strokeColor: .green, strokeWidth: 4)
        try expectApprox(a.startPoint.x, 10); try expectApprox(a.endPoint.x, 100)
    }

    test("hitTest on line") {
        let a = ArrowAnnotation(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 100, y: 0), strokeWidth: 2)
        try expect(a.hitTest(point: CGPoint(x: 50, y: 0)))
        try expect(a.hitTest(point: CGPoint(x: 50, y: 5)))
    }

    test("hitTest far") {
        let a = ArrowAnnotation(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 100, y: 0), strokeWidth: 2)
        try expect(!a.hitTest(point: CGPoint(x: 50, y: 50)))
    }

    test("boundingRect encompasses endpoints") {
        let a = ArrowAnnotation(start: CGPoint(x: 20, y: 20), end: CGPoint(x: 80, y: 80))
        let br = a.boundingRect()
        try expect(br.contains(CGPoint(x: 20, y: 20)))
        try expect(br.contains(CGPoint(x: 80, y: 80)))
    }

    test("copy is independent") {
        let a = ArrowAnnotation(start: CGPoint(x: 10, y: 10), end: CGPoint(x: 50, y: 50))
        let b = a.copy() as! ArrowAnnotation
        try expect(b.id != a.id)
        b.startPoint = CGPoint(x: 999, y: 999)
        try expectApprox(a.startPoint.x, 10)
    }

    test("draw does not crash") {
        let a = ArrowAnnotation(start: CGPoint(x: 10, y: 10), end: CGPoint(x: 90, y: 90))
        a.draw(in: makeContext(), scale: 1.0)
    }

    // ─── TextAnnotation ───

    suite("TextAnnotation")

    test("init sets properties") {
        let a = TextAnnotation(position: CGPoint(x: 25, y: 75), text: "Hello")
        try expectApprox(a.position.x, 25)
        try expectEqual(a.text, "Hello")
    }

    test("hitTest at bounding rect center") {
        let a = TextAnnotation(position: CGPoint(x: 10, y: 10), text: "Test text here")
        let br = a.boundingRect()
        try expect(a.hitTest(point: CGPoint(x: br.midX, y: br.midY)))
    }

    test("hitTest far away") {
        let a = TextAnnotation(position: CGPoint(x: 10, y: 10), text: "Test")
        try expect(!a.hitTest(point: CGPoint(x: 500, y: 500)))
    }

    test("boundingRect non-empty for text") {
        let a = TextAnnotation(position: CGPoint(x: 10, y: 10), text: "Some text")
        let br = a.boundingRect()
        try expect(br.width > 0); try expect(br.height > 0)
    }

    test("copy is independent") {
        let a = TextAnnotation(position: CGPoint(x: 10, y: 20), text: "Hello", strokeColor: .blue)
        let b = a.copy() as! TextAnnotation
        try expect(b.id != a.id)
        try expectEqual(b.text, "Hello")
        b.text = "Changed"
        try expectEqual(a.text, "Hello")
    }

    // ─── FreehandAnnotation ───

    suite("FreehandAnnotation")

    test("init creates empty points") {
        let a = FreehandAnnotation()
        try expect(a.points.isEmpty)
    }

    test("addPoint appends") {
        let a = FreehandAnnotation()
        a.addPoint(CGPoint(x: 10, y: 10))
        a.addPoint(CGPoint(x: 20, y: 20))
        a.addPoint(CGPoint(x: 30, y: 30))
        try expectEqual(a.points.count, 3)
    }

    test("hitTest on path") {
        let a = FreehandAnnotation(strokeWidth: 4)
        a.addPoint(CGPoint(x: 0, y: 0))
        a.addPoint(CGPoint(x: 100, y: 0))
        try expect(a.hitTest(point: CGPoint(x: 50, y: 0)))
    }

    test("hitTest far") {
        let a = FreehandAnnotation(strokeWidth: 2)
        a.addPoint(CGPoint(x: 0, y: 0))
        a.addPoint(CGPoint(x: 100, y: 0))
        try expect(!a.hitTest(point: CGPoint(x: 50, y: 50)))
    }

    test("hitTest with single point returns false") {
        let a = FreehandAnnotation()
        a.addPoint(CGPoint(x: 50, y: 50))
        try expect(!a.hitTest(point: CGPoint(x: 50, y: 50)))
    }

    test("boundingRect encompasses all points") {
        let a = FreehandAnnotation(strokeWidth: 2)
        a.addPoint(CGPoint(x: 10, y: 10))
        a.addPoint(CGPoint(x: 90, y: 90))
        a.addPoint(CGPoint(x: 50, y: 5))
        let br = a.boundingRect()
        try expect(br.contains(CGPoint(x: 10, y: 10)))
        try expect(br.contains(CGPoint(x: 90, y: 90)))
    }

    test("boundingRect empty for no points") {
        let a = FreehandAnnotation()
        try expect(a.boundingRect() == .zero)
    }

    test("copy is independent") {
        let a = FreehandAnnotation(strokeColor: .orange, strokeWidth: 5)
        a.addPoint(CGPoint(x: 10, y: 10))
        a.addPoint(CGPoint(x: 20, y: 20))
        let b = a.copy() as! FreehandAnnotation
        try expect(b.id != a.id)
        try expectEqual(b.points.count, 2)
        b.addPoint(CGPoint(x: 30, y: 30))
        try expectEqual(a.points.count, 2)
    }

    test("draw with few points does not crash") {
        let a = FreehandAnnotation()
        a.addPoint(CGPoint(x: 10, y: 10))
        a.draw(in: makeContext(), scale: 1.0)
    }

    test("draw with many points does not crash") {
        let a = FreehandAnnotation()
        for i in 0..<50 { a.addPoint(CGPoint(x: Double(i) * 2, y: Double(i) * 2)) }
        a.draw(in: makeContext(), scale: 1.0)
    }

    // ─── HighlightAnnotation ───

    suite("HighlightAnnotation")

    test("init defaults to yellow") {
        let a = HighlightAnnotation(origin: .zero, end: CGPoint(x: 10, y: 10))
        try expect(a.strokeColor == .systemYellow)
    }

    test("rect normalizes") {
        let a = HighlightAnnotation(origin: CGPoint(x: 50, y: 50), end: CGPoint(x: 10, y: 10))
        try expectApprox(a.rect.origin.x, 10)
        try expectApprox(a.rect.width, 40)
    }

    test("hitTest inside") {
        let a = HighlightAnnotation(origin: CGPoint(x: 10, y: 10), end: CGPoint(x: 50, y: 50))
        try expect(a.hitTest(point: CGPoint(x: 30, y: 30)))
    }

    test("hitTest outside") {
        let a = HighlightAnnotation(origin: CGPoint(x: 10, y: 10), end: CGPoint(x: 50, y: 50))
        try expect(!a.hitTest(point: CGPoint(x: 200, y: 200)))
    }

    test("copy is independent") {
        let a = HighlightAnnotation(origin: CGPoint(x: 10, y: 10), end: CGPoint(x: 50, y: 50))
        let b = a.copy() as! HighlightAnnotation
        try expect(b.id != a.id)
        b.origin = CGPoint(x: 999, y: 999)
        try expectApprox(a.origin.x, 10)
    }

    test("draw does not crash") {
        let a = HighlightAnnotation(origin: CGPoint(x: 5, y: 5), end: CGPoint(x: 50, y: 50))
        a.draw(in: makeContext(), scale: 1.0)
    }

    // ─── BlurAnnotation ───

    suite("BlurAnnotation")

    test("init sets properties") {
        let a = BlurAnnotation(origin: CGPoint(x: 10, y: 10), end: CGPoint(x: 50, y: 50))
        try expectApprox(a.blurRadius, Constants.defaultBlurRadius)
        try expect(a.strokeColor == .clear)
    }

    test("rect normalizes") {
        let a = BlurAnnotation(origin: CGPoint(x: 80, y: 80), end: CGPoint(x: 20, y: 20))
        try expectApprox(a.rect.origin.x, 20)
        try expectApprox(a.rect.width, 60)
    }

    test("hitTest inside") {
        let a = BlurAnnotation(origin: CGPoint(x: 10, y: 10), end: CGPoint(x: 50, y: 50))
        try expect(a.hitTest(point: CGPoint(x: 30, y: 30)))
    }

    test("hitTest outside") {
        let a = BlurAnnotation(origin: CGPoint(x: 10, y: 10), end: CGPoint(x: 50, y: 50))
        try expect(!a.hitTest(point: CGPoint(x: 200, y: 200)))
    }

    test("copy is independent") {
        let a = BlurAnnotation(origin: CGPoint(x: 10, y: 10), end: CGPoint(x: 50, y: 50), blurRadius: 15)
        let b = a.copy() as! BlurAnnotation
        try expect(b.id != a.id)
        try expectApprox(b.blurRadius, 15)
        b.origin = CGPoint(x: 999, y: 999)
        try expectApprox(a.origin.x, 10)
    }

    test("draw does not crash") {
        let a = BlurAnnotation(origin: CGPoint(x: 5, y: 5), end: CGPoint(x: 50, y: 50))
        a.draw(in: makeContext(), scale: 1.0)
    }

    // ─── AnnotationTool Enum ───

    suite("AnnotationTool")

    test("allCases has 7 tools") {
        try expectEqual(AnnotationTool.allCases.count, 7)
    }

    test("each tool has non-empty sfSymbolName") {
        for tool in AnnotationTool.allCases {
            try expect(!tool.sfSymbolName.isEmpty, "sfSymbolName empty for \(tool)")
        }
    }

    test("rawValue round-trips") {
        for tool in AnnotationTool.allCases {
            try expect(AnnotationTool(rawValue: tool.rawValue) == tool)
        }
    }
}
