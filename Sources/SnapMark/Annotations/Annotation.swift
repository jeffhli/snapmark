import AppKit
import CoreGraphics

enum AnnotationTool: String, CaseIterable {
    case select = "Select"
    case rectangle = "Rectangle"
    case arrow = "Arrow"
    case text = "Text"
    case freehand = "Pen"
    case highlight = "Highlight"
    case blur = "Blur"

    var sfSymbolName: String {
        switch self {
        case .select: return "cursorarrow"
        case .rectangle: return "rectangle"
        case .arrow: return "arrow.up.right"
        case .text: return "textformat"
        case .freehand: return "pencil.tip"
        case .highlight: return "highlighter"
        case .blur: return "aqi.medium"
        }
    }
}

protocol Annotation: AnyObject {
    var id: UUID { get }
    var strokeColor: NSColor { get set }
    var strokeWidth: CGFloat { get set }
    func draw(in context: CGContext, scale: CGFloat)
    func hitTest(point: CGPoint) -> Bool
    func boundingRect() -> CGRect
    func copy() -> Annotation
}
