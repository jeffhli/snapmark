import AppKit

final class CanvasView: NSView {
    let baseImage: NSImage
    var annotations: [Annotation] = []
    var currentTool: AnnotationTool = .rectangle
    var currentColor: NSColor = Constants.defaultStrokeColor
    var currentStrokeWidth: CGFloat = Constants.defaultStrokeWidth
    let history = AnnotationHistory()

    // Active drawing state
    private var activeAnnotation: Annotation?
    private var dragStart: CGPoint?
    private var selectedIndex: Int?

    // Text input
    private var textField: NSTextField?
    private var textInsertPoint: CGPoint?

    // Delegate for toolbar state updates
    weak var delegate: CanvasViewDelegate?

    init(image: NSImage) {
        self.baseImage = image
        super.init(frame: CGRect(origin: .zero, size: image.size))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { false }
    override var intrinsicContentSize: NSSize { baseImage.size }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Draw base image using NSImage.draw which handles coordinate systems
        // correctly in all NSView configurations without any manual flip transform.
        baseImage.draw(in: bounds, from: .zero, operation: .copy, fraction: 1.0)

        // Draw annotations
        let scale = window?.backingScaleFactor ?? 1.0
        for (i, annotation) in annotations.enumerated() {
            context.saveGState()
            annotation.draw(in: context, scale: scale)
            context.restoreGState()

            // Draw selection handles
            if i == selectedIndex {
                drawSelectionHandles(for: annotation, in: context)
            }
        }

        // Draw active (in-progress) annotation
        if let active = activeAnnotation {
            context.saveGState()
            active.draw(in: context, scale: scale)
            context.restoreGState()
        }
    }

    private func drawSelectionHandles(for annotation: Annotation, in context: CGContext) {
        let rect = annotation.boundingRect()
        let handleSize: CGFloat = 6
        let handles = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY),
        ]

        context.setFillColor(NSColor.white.cgColor)
        context.setStrokeColor(NSColor.systemBlue.cgColor)
        context.setLineWidth(1)

        for h in handles {
            let r = CGRect(x: h.x - handleSize / 2, y: h.y - handleSize / 2,
                           width: handleSize, height: handleSize)
            context.fillEllipse(in: r)
            context.strokeEllipse(in: r)
        }

        // Dashed border
        context.setStrokeColor(NSColor.systemBlue.withAlphaComponent(0.6).cgColor)
        context.setLineWidth(1)
        context.setLineDash(phase: 0, lengths: [4, 4])
        context.stroke(rect)
        context.setLineDash(phase: 0, lengths: [])
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        dragStart = point

        commitTextFieldIfNeeded()

        if currentTool == .select {
            // Try to select an existing annotation
            selectedIndex = nil
            for i in stride(from: annotations.count - 1, through: 0, by: -1) {
                if annotations[i].hitTest(point: point) {
                    selectedIndex = i
                    break
                }
            }
            needsDisplay = true
            return
        }

        if currentTool == .text {
            textInsertPoint = point
            showTextField(at: point)
            return
        }

        // Start creating a new annotation
        selectedIndex = nil
        switch currentTool {
        case .rectangle:
            activeAnnotation = RectangleAnnotation(origin: point, end: point,
                                                    strokeColor: currentColor, strokeWidth: currentStrokeWidth)
        case .arrow:
            activeAnnotation = ArrowAnnotation(start: point, end: point,
                                               strokeColor: currentColor, strokeWidth: currentStrokeWidth)
        case .freehand:
            let freehand = FreehandAnnotation(strokeColor: currentColor, strokeWidth: currentStrokeWidth)
            freehand.addPoint(point)
            activeAnnotation = freehand
        case .highlight:
            activeAnnotation = HighlightAnnotation(origin: point, end: point,
                                                    strokeColor: currentColor, strokeWidth: currentStrokeWidth)
        case .blur:
            activeAnnotation = BlurAnnotation(origin: point, end: point)
        default:
            break
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if currentTool == .select, let idx = selectedIndex, let start = dragStart {
            // Move selected annotation
            let dx = point.x - start.x
            let dy = point.y - start.y
            moveAnnotation(at: idx, by: CGVector(dx: dx, dy: dy))
            dragStart = point
            needsDisplay = true
            return
        }

        // Update active annotation geometry
        if let rect = activeAnnotation as? RectangleAnnotation {
            rect.end = point
        } else if let arrow = activeAnnotation as? ArrowAnnotation {
            arrow.endPoint = point
        } else if let freehand = activeAnnotation as? FreehandAnnotation {
            freehand.addPoint(point)
        } else if let highlight = activeAnnotation as? HighlightAnnotation {
            highlight.end = point
        } else if let blur = activeAnnotation as? BlurAnnotation {
            blur.end = point
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if let active = activeAnnotation {
            // Don't add zero-size annotations
            let br = active.boundingRect()
            if br.width > 2 || br.height > 2 {
                pushUndo()
                annotations.append(active)
            }
            activeAnnotation = nil
            needsDisplay = true
            delegate?.canvasDidUpdate(self)
        }
        dragStart = nil
    }

    // MARK: - Move Annotation

    private func moveAnnotation(at index: Int, by delta: CGVector) {
        let a = annotations[index]
        if let rect = a as? RectangleAnnotation {
            rect.origin.x += delta.dx; rect.origin.y += delta.dy
            rect.end.x += delta.dx; rect.end.y += delta.dy
        } else if let arrow = a as? ArrowAnnotation {
            arrow.startPoint.x += delta.dx; arrow.startPoint.y += delta.dy
            arrow.endPoint.x += delta.dx; arrow.endPoint.y += delta.dy
        } else if let text = a as? TextAnnotation {
            text.position.x += delta.dx; text.position.y += delta.dy
        } else if let freehand = a as? FreehandAnnotation {
            for i in 0..<freehand.points.count {
                freehand.points[i].x += delta.dx
                freehand.points[i].y += delta.dy
            }
        } else if let highlight = a as? HighlightAnnotation {
            highlight.origin.x += delta.dx; highlight.origin.y += delta.dy
            highlight.end.x += delta.dx; highlight.end.y += delta.dy
        } else if let blur = a as? BlurAnnotation {
            blur.origin.x += delta.dx; blur.origin.y += delta.dy
            blur.end.x += delta.dx; blur.end.y += delta.dy
        }
    }

    // MARK: - Text Input

    private func showTextField(at point: CGPoint) {
        let field = NSTextField(frame: CGRect(x: point.x, y: point.y - 10, width: 200, height: 24))
        field.font = Constants.defaultFont
        field.textColor = currentColor
        field.backgroundColor = NSColor.white.withAlphaComponent(0.9)
        field.isBordered = true
        field.isEditable = true
        field.focusRingType = .none
        field.target = self
        field.action = #selector(textFieldCommit)
        addSubview(field)
        window?.makeFirstResponder(field)
        textField = field
    }

    @objc private func textFieldCommit() {
        commitTextFieldIfNeeded()
    }

    private func commitTextFieldIfNeeded() {
        guard let field = textField, let point = textInsertPoint else { return }
        let text = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        field.removeFromSuperview()
        textField = nil

        if !text.isEmpty {
            pushUndo()
            let annotation = TextAnnotation(position: point, text: text,
                                            strokeColor: currentColor, strokeWidth: currentStrokeWidth)
            annotations.append(annotation)
            needsDisplay = true
            delegate?.canvasDidUpdate(self)
        }
        textInsertPoint = nil
    }

    // MARK: - Keyboard

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers {
            case "z":
                if event.modifierFlags.contains(.shift) {
                    redo()
                } else {
                    undo()
                }
            case "s":
                save()
            case "c":
                copyToClipboard()
            default:
                super.keyDown(with: event)
            }
        } else if event.keyCode == 51 || event.keyCode == 117 { // Delete, Forward Delete
            deleteSelected()
        } else if event.keyCode == 53 { // Escape
            selectedIndex = nil
            commitTextFieldIfNeeded()
            needsDisplay = true
        } else {
            super.keyDown(with: event)
        }
    }

    // MARK: - Undo / Redo

    func pushUndo() {
        history.push(annotations)
    }

    func undo() {
        if let state = history.undo(current: annotations) {
            annotations = state
            selectedIndex = nil
            needsDisplay = true
            delegate?.canvasDidUpdate(self)
        }
    }

    func redo() {
        if let state = history.redo(current: annotations) {
            annotations = state
            selectedIndex = nil
            needsDisplay = true
            delegate?.canvasDidUpdate(self)
        }
    }

    func deleteSelected() {
        guard let idx = selectedIndex, idx < annotations.count else { return }
        pushUndo()
        annotations.remove(at: idx)
        selectedIndex = nil
        needsDisplay = true
        delegate?.canvasDidUpdate(self)
    }

    // MARK: - Export

    func save() {
        SavePanelHelper.saveImage(baseImage, annotations: annotations, from: window)
    }

    func copyToClipboard() {
        ImageExporter.copyToClipboard(image: baseImage, annotations: annotations)
        // Brief flash feedback
        let overlay = NSView(frame: bounds)
        overlay.wantsLayer = true
        overlay.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.3).cgColor
        addSubview(overlay)
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.2
            overlay.animator().alphaValue = 0
        }, completionHandler: {
            overlay.removeFromSuperview()
        })
    }
}

protocol CanvasViewDelegate: AnyObject {
    func canvasDidUpdate(_ canvas: CanvasView)
}
