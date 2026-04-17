import AppKit
@testable import SnapMarkLib

func makeTestImage(width: Int = 100, height: Int = 80) -> NSImage {
    let image = NSImage(size: NSSize(width: width, height: height))
    image.lockFocus()
    NSColor.blue.setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    image.unlockFocus()
    return image
}

func runImageExporterTests() {
    suite("ImageExporter")

    test("renderImage with no annotations") {
        let image = makeTestImage()
        let result = try expectNotNil(ImageExporter.renderImage(baseImage: image, annotations: []))
        try expectApprox(result.size.width, 100)
        try expectApprox(result.size.height, 80)
    }

    test("renderImage with rectangle and arrow") {
        let image = makeTestImage()
        let rect = RectangleAnnotation(origin: CGPoint(x: 10, y: 10), end: CGPoint(x: 50, y: 50), strokeColor: .red, strokeWidth: 2)
        let arrow = ArrowAnnotation(start: CGPoint(x: 10, y: 10), end: CGPoint(x: 80, y: 70))
        let result = try expectNotNil(ImageExporter.renderImage(baseImage: image, annotations: [rect, arrow]))
        try expect(result.size.width > 0)
    }

    test("renderImage with all annotation types") {
        let image = makeTestImage(width: 200, height: 200)
        var annotations: [Annotation] = []
        annotations.append(RectangleAnnotation(origin: CGPoint(x: 10, y: 10), end: CGPoint(x: 50, y: 50)))
        annotations.append(ArrowAnnotation(start: CGPoint(x: 60, y: 60), end: CGPoint(x: 120, y: 120)))
        annotations.append(TextAnnotation(position: CGPoint(x: 10, y: 150), text: "Test annotation"))
        let freehand = FreehandAnnotation()
        freehand.addPoint(CGPoint(x: 130, y: 10)); freehand.addPoint(CGPoint(x: 150, y: 30)); freehand.addPoint(CGPoint(x: 170, y: 10))
        annotations.append(freehand)
        annotations.append(HighlightAnnotation(origin: CGPoint(x: 100, y: 100), end: CGPoint(x: 180, y: 140)))
        annotations.append(BlurAnnotation(origin: CGPoint(x: 130, y: 130), end: CGPoint(x: 190, y: 190)))

        let result = try expectNotNil(ImageExporter.renderImage(baseImage: image, annotations: annotations))
        try expect(result.size.width > 0)
    }

    test("pngData returns valid PNG") {
        let image = makeTestImage()
        let data = try expectNotNil(ImageExporter.pngData(from: image))
        try expect(data.count > 0)
        // PNG magic bytes: 0x89 P N G
        try expectEqual(data[0], 0x89)
        try expectEqual(data[1], 0x50)
        try expectEqual(data[2], 0x4E)
        try expectEqual(data[3], 0x47)
    }

    test("pngData roundtrip creates valid image") {
        let image = makeTestImage(width: 50, height: 50)
        let data = try expectNotNil(ImageExporter.pngData(from: image))
        let restored = try expectNotNil(NSImage(data: data))
        try expect(restored.size.width > 0)
        try expect(restored.size.height > 0)
    }

    test("renderImage then pngData produces valid PNG") {
        let image = makeTestImage()
        let rect = RectangleAnnotation(origin: CGPoint(x: 5, y: 5), end: CGPoint(x: 80, y: 60), strokeColor: .green)
        let rendered = try expectNotNil(ImageExporter.renderImage(baseImage: image, annotations: [rect]))
        let data = try expectNotNil(ImageExporter.pngData(from: rendered))
        try expect(data.count > 0)
    }

    test("copyToClipboard puts image on pasteboard") {
        let image = makeTestImage()
        ImageExporter.copyToClipboard(image: image, annotations: [])
        let pb = NSPasteboard.general
        let types = pb.types ?? []
        try expect(types.contains(.tiff) || types.contains(.png), "clipboard should have image data")
    }

    test("copyToClipboard with annotations") {
        let image = makeTestImage()
        let rect = RectangleAnnotation(origin: CGPoint(x: 5, y: 5), end: CGPoint(x: 50, y: 50))
        ImageExporter.copyToClipboard(image: image, annotations: [rect])
        let pb = NSPasteboard.general
        let types = pb.types ?? []
        try expect(types.contains(.tiff) || types.contains(.png), "clipboard should have image data")
    }
}
