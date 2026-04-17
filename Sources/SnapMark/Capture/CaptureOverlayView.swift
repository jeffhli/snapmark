import AppKit

final class CaptureOverlayView: NSView {
    private var startPoint: CGPoint?
    private var currentPoint: CGPoint?
    private var isSelecting = false

    private var captureWindow: CaptureOverlayWindow? {
        return self.window as? CaptureOverlayWindow
    }

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.window?.makeFirstResponder(self)
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Draw dim overlay
        context.setFillColor(Constants.overlayDimColor.cgColor)
        context.fill(bounds)

        // Draw selection if active
        guard let start = startPoint, let current = currentPoint, isSelecting else {
            // Draw crosshair at mouse position
            drawCrosshair(context: context)
            return
        }

        let selectionRect = GeometryHelpers.normalizedRect(from: start, to: current)
        guard selectionRect.width > 0, selectionRect.height > 0 else { return }

        // Clear the selection area to show screen beneath
        context.clear(selectionRect)

        // Draw selection border
        context.setStrokeColor(Constants.selectionBorderColor.cgColor)
        context.setLineWidth(Constants.selectionBorderWidth)
        context.stroke(selectionRect)

        // Draw dimension label
        drawDimensionLabel(rect: selectionRect, context: context)

        // Draw crosshairs extending to edges
        drawSelectionGuides(rect: selectionRect, context: context)
    }

    private func drawCrosshair(context: CGContext) {
        guard let mouseLocation = self.window?.mouseLocationOutsideOfEventStream else { return }
        let point = convert(mouseLocation, from: nil)

        context.setStrokeColor(NSColor.white.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(0.5)
        context.setLineDash(phase: 0, lengths: [4, 4])

        // Horizontal line
        context.move(to: CGPoint(x: bounds.minX, y: point.y))
        context.addLine(to: CGPoint(x: bounds.maxX, y: point.y))
        context.strokePath()

        // Vertical line
        context.move(to: CGPoint(x: point.x, y: bounds.minY))
        context.addLine(to: CGPoint(x: point.x, y: bounds.maxY))
        context.strokePath()

        context.setLineDash(phase: 0, lengths: [])
    }

    private func drawSelectionGuides(rect: CGRect, context: CGContext) {
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.2).cgColor)
        context.setLineWidth(0.5)
        context.setLineDash(phase: 0, lengths: [2, 2])

        // Extend selection edges
        let edges: [(CGPoint, CGPoint)] = [
            (CGPoint(x: rect.minX, y: bounds.minY), CGPoint(x: rect.minX, y: bounds.maxY)),
            (CGPoint(x: rect.maxX, y: bounds.minY), CGPoint(x: rect.maxX, y: bounds.maxY)),
            (CGPoint(x: bounds.minX, y: rect.minY), CGPoint(x: bounds.maxX, y: rect.minY)),
            (CGPoint(x: bounds.minX, y: rect.maxY), CGPoint(x: bounds.maxX, y: rect.maxY)),
        ]
        for (a, b) in edges {
            context.move(to: a)
            context.addLine(to: b)
        }
        context.strokePath()
        context.setLineDash(phase: 0, lengths: [])
    }

    private func drawDimensionLabel(rect: CGRect, context: CGContext) {
        let scaleFactor = self.window?.backingScaleFactor ?? 1.0
        let w = Int(rect.width * scaleFactor)
        let h = Int(rect.height * scaleFactor)
        let text = "\(w) × \(h)" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor.white,
        ]
        let textSize = text.size(withAttributes: attrs)
        let padding: CGFloat = 6
        let bgRect = CGRect(
            x: rect.midX - textSize.width / 2 - padding,
            y: rect.minY - textSize.height - padding * 2 - 4,
            width: textSize.width + padding * 2,
            height: textSize.height + padding
        )

        // Background pill
        let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: 4, yRadius: 4)
        NSColor.black.withAlphaComponent(0.7).setFill()
        bgPath.fill()

        // Text
        let textPoint = CGPoint(x: bgRect.origin.x + padding, y: bgRect.origin.y + padding / 2)
        text.draw(at: textPoint, withAttributes: attrs)
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        startPoint = point
        currentPoint = point
        isSelecting = true
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let start = startPoint else { return }
        let end = convert(event.locationInWindow, from: nil)
        let selectionRect = GeometryHelpers.normalizedRect(from: start, to: end)

        isSelecting = false
        startPoint = nil
        currentPoint = nil

        guard selectionRect.width > 3, selectionRect.height > 3 else {
            needsDisplay = true
            return
        }

        // Convert view rect to screen coordinates
        guard let screenFrame = self.window?.frame else { return }
        let screenRect = CGRect(
            x: screenFrame.origin.x + selectionRect.origin.x,
            y: screenFrame.origin.y + selectionRect.origin.y,
            width: selectionRect.width,
            height: selectionRect.height
        )

        captureWindow?.onCaptureComplete?(screenRect, screenFrame)
    }

    override func mouseMoved(with event: NSEvent) {
        if !isSelecting {
            needsDisplay = true
        }
    }

    // MARK: - Keyboard

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            captureWindow?.onCancel?()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        captureWindow?.onCancel?()
    }

    // MARK: - Cursor

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }
}
