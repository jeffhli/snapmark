import AppKit
@testable import SnapMarkLib

func runIntegrationTests() {

    // ─── CanvasView ───

    suite("CanvasView Integration")

    test("init with empty annotations") {
        let canvas = CanvasView(image: makeTestImage(width: 200, height: 200))
        try expect(canvas.annotations.isEmpty)
        try expect(canvas.currentTool == .rectangle)
        try expectApprox(canvas.currentStrokeWidth, Constants.defaultStrokeWidth)
    }

    test("tool switching") {
        let canvas = CanvasView(image: makeTestImage(width: 200, height: 200))
        for tool in AnnotationTool.allCases {
            canvas.currentTool = tool
            try expect(canvas.currentTool == tool)
        }
    }

    test("color and strokeWidth changes") {
        let canvas = CanvasView(image: makeTestImage(width: 200, height: 200))
        canvas.currentColor = .blue
        try expect(canvas.currentColor == .blue)
        canvas.currentStrokeWidth = 10
        try expectApprox(canvas.currentStrokeWidth, 10)
    }

    test("pushUndo then undo restores empty state") {
        let canvas = CanvasView(image: makeTestImage(width: 200, height: 200))
        canvas.pushUndo()
        canvas.annotations.append(RectangleAnnotation(origin: .zero, end: CGPoint(x: 10, y: 10)))
        try expectEqual(canvas.annotations.count, 1)
        canvas.undo()
        try expectEqual(canvas.annotations.count, 0)
    }

    test("redo after undo restores annotations") {
        let canvas = CanvasView(image: makeTestImage(width: 200, height: 200))
        canvas.pushUndo()
        canvas.annotations.append(RectangleAnnotation(origin: .zero, end: CGPoint(x: 10, y: 10)))
        canvas.pushUndo()
        canvas.annotations.append(RectangleAnnotation(origin: CGPoint(x: 20, y: 20), end: CGPoint(x: 40, y: 40)))
        try expectEqual(canvas.annotations.count, 2)
        canvas.undo()
        try expectEqual(canvas.annotations.count, 1)
        canvas.redo()
        try expectEqual(canvas.annotations.count, 2)
    }

    test("multiple undo/redo cycles") {
        let canvas = CanvasView(image: makeTestImage(width: 200, height: 200))
        canvas.pushUndo()
        canvas.annotations.append(RectangleAnnotation(origin: .zero, end: CGPoint(x: 10, y: 10)))
        canvas.pushUndo()
        canvas.annotations.append(ArrowAnnotation(start: .zero, end: CGPoint(x: 20, y: 20)))
        canvas.pushUndo()
        canvas.annotations.append(HighlightAnnotation(origin: CGPoint(x: 30, y: 30), end: CGPoint(x: 50, y: 50)))

        try expectEqual(canvas.annotations.count, 3)
        canvas.undo(); try expectEqual(canvas.annotations.count, 2)
        canvas.undo(); try expectEqual(canvas.annotations.count, 1)
        canvas.undo(); try expectEqual(canvas.annotations.count, 0)
        canvas.redo(); try expectEqual(canvas.annotations.count, 1)
        canvas.redo(); try expectEqual(canvas.annotations.count, 2)
        canvas.redo(); try expectEqual(canvas.annotations.count, 3)
    }

    test("history state accessible") {
        let canvas = CanvasView(image: makeTestImage(width: 200, height: 200))
        try expect(!canvas.history.canUndo)
        canvas.pushUndo()
        try expect(canvas.history.canUndo)
    }

    test("acceptsFirstResponder is true") {
        let canvas = CanvasView(image: makeTestImage(width: 200, height: 200))
        try expect(canvas.acceptsFirstResponder)
    }

    test("isFlipped is false") {
        let canvas = CanvasView(image: makeTestImage(width: 200, height: 200))
        try expect(!canvas.isFlipped)
    }

    // ─── EditorWindowController ───

    suite("EditorWindowController Integration")

    test("init creates window") {
        let c = EditorWindowController(image: makeTestImage(width: 400, height: 300))
        try expect(c.window != nil)
        try expectEqual(c.window!.title, "SnapMark")
        try expect(c.window!.minSize == Constants.minEditorSize)
        try expect(!c.window!.isReleasedWhenClosed)
    }

    test("window has subviews (toolbar + canvas)") {
        let c = EditorWindowController(image: makeTestImage(width: 400, height: 300))
        try expect(c.window!.contentView!.subviews.count >= 2)
    }

    test("toolbar tool selection does not crash") {
        let c = EditorWindowController(image: makeTestImage(width: 400, height: 300))
        c.toolbarDidSelectTool(.arrow)
        c.toolbarDidSelectTool(.text)
        c.toolbarDidSelectTool(.freehand)
    }

    test("toolbar color change does not crash") {
        let c = EditorWindowController(image: makeTestImage(width: 400, height: 300))
        c.toolbarDidChangeColor(.purple)
    }

    test("toolbar stroke width change does not crash") {
        let c = EditorWindowController(image: makeTestImage(width: 400, height: 300))
        c.toolbarDidChangeStrokeWidth(8)
    }

    test("undo/redo on empty state does not crash") {
        let c = EditorWindowController(image: makeTestImage(width: 400, height: 300))
        c.toolbarDidRequestUndo()
        c.toolbarDidRequestRedo()
    }

    test("copy request puts data on clipboard") {
        let c = EditorWindowController(image: makeTestImage(width: 400, height: 300))
        c.toolbarDidRequestCopy()
        let types = NSPasteboard.general.types ?? []
        try expect(types.contains(.tiff) || types.contains(.png))
    }

    // ─── ToolbarView ───

    suite("ToolbarView")

    test("init creates subviews") {
        let toolbar = ToolbarView(frame: CGRect(x: 0, y: 0, width: 600, height: 48))
        try expect(toolbar.subviews.count > 0)
    }

    test("delegate can be set") {
        final class MockDelegate: ToolbarDelegate {
            func toolbarDidSelectTool(_ tool: AnnotationTool) {}
            func toolbarDidChangeColor(_ color: NSColor) {}
            func toolbarDidChangeStrokeWidth(_ width: CGFloat) {}
            func toolbarDidRequestUndo() {}
            func toolbarDidRequestRedo() {}
            func toolbarDidRequestCopy() {}
            func toolbarDidRequestSave() {}
        }
        let toolbar = ToolbarView(frame: CGRect(x: 0, y: 0, width: 600, height: 48))
        let mock = MockDelegate()
        toolbar.delegate = mock
        try expect(toolbar.delegate === mock)
    }

    // ─── Constants ───

    suite("Constants")

    test("default values are sensible") {
        try expect(Constants.defaultStrokeWidth > 0)
        try expect(Constants.defaultFontSize > 0)
        try expect(Constants.toolbarHeight > 0)
        try expect(Constants.minEditorSize.width > 0)
        try expect(Constants.minEditorSize.height > 0)
        try expect(Constants.maxUndoDepth > 0)
        try expect(Constants.defaultBlurRadius > 0)
    }
}
