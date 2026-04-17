import AppKit
import CoreGraphics

final class TextAnnotation: Annotation {
    let id = UUID()
    var strokeColor: NSColor
    var strokeWidth: CGFloat
    var position: CGPoint
    var text: String
    var font: NSFont

    init(position: CGPoint, text: String, strokeColor: NSColor = Constants.defaultStrokeColor,
         strokeWidth: CGFloat = Constants.defaultStrokeWidth, font: NSFont = Constants.defaultFont) {
        self.position = position
        self.text = text
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.font = font
    }

    func draw(in context: CGContext, scale: CGFloat) {
        guard !text.isEmpty else { return }
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: strokeColor,
        ]
        let nsString = text as NSString
        // Use NSGraphicsContext for text drawing
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        nsString.draw(at: position, withAttributes: attrs)
        NSGraphicsContext.restoreGraphicsState()
    }

    func hitTest(point: CGPoint) -> Bool {
        boundingRect().contains(point)
    }

    func boundingRect() -> CGRect {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let size = (text as NSString).size(withAttributes: attrs)
        return CGRect(origin: position, size: size).insetBy(dx: -4, dy: -4)
    }

    func copy() -> Annotation {
        TextAnnotation(position: position, text: text, strokeColor: strokeColor,
                       strokeWidth: strokeWidth, font: font)
    }
}
