import AppKit

final class EditorWindowController: NSWindowController, NSWindowDelegate, ToolbarDelegate, CanvasViewDelegate {
    private let image: NSImage
    private var canvasView: CanvasView!
    private var toolbarView: ToolbarView!
    private var scrollView: NSScrollView!
    var onClose: ((EditorWindowController) -> Void)?

    init(image: NSImage) {
        self.image = image

        // Calculate window size (fit image, cap at 80% of screen)
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let maxW = screen.visibleFrame.width * 0.8
        let maxH = screen.visibleFrame.height * 0.8
        let imgW = image.size.width
        let imgH = image.size.height
        let scale = min(1.0, min(maxW / imgW, maxH / (imgH + Constants.toolbarHeight)))
        let winW = imgW * scale
        let winH = imgH * scale + Constants.toolbarHeight

        let contentRect = CGRect(
            x: (screen.visibleFrame.width - winW) / 2 + screen.visibleFrame.origin.x,
            y: (screen.visibleFrame.height - winH) / 2 + screen.visibleFrame.origin.y,
            width: winW,
            height: winH
        )

        let window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "SnapMark"
        window.minSize = Constants.minEditorSize
        window.isReleasedWhenClosed = false

        super.init(window: window)
        window.delegate = self
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        guard let contentView = window?.contentView else { return }

        // Toolbar at top
        toolbarView = ToolbarView(frame: .zero)
        toolbarView.delegate = self
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(toolbarView)

        // Canvas below toolbar
        canvasView = CanvasView(image: image)
        canvasView.delegate = self

        scrollView = NSScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = NSColor.windowBackgroundColor
        scrollView.drawsBackground = true
        scrollView.documentView = canvasView
        contentView.addSubview(scrollView)

        NSLayoutConstraint.activate([
            toolbarView.topAnchor.constraint(equalTo: contentView.topAnchor),
            toolbarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            toolbarView.heightAnchor.constraint(equalToConstant: Constants.toolbarHeight),

            scrollView.topAnchor.constraint(equalTo: toolbarView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        window?.makeFirstResponder(canvasView)
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
    }

    // MARK: - ToolbarDelegate

    func toolbarDidSelectTool(_ tool: AnnotationTool) {
        canvasView.currentTool = tool
    }

    func toolbarDidChangeColor(_ color: NSColor) {
        canvasView.currentColor = color
    }

    func toolbarDidChangeStrokeWidth(_ width: CGFloat) {
        canvasView.currentStrokeWidth = width
    }

    func toolbarDidRequestUndo() {
        canvasView.undo()
    }

    func toolbarDidRequestRedo() {
        canvasView.redo()
    }

    func toolbarDidRequestCopy() {
        canvasView.copyToClipboard()
    }

    func toolbarDidRequestSave() {
        canvasView.save()
    }

    // MARK: - CanvasViewDelegate

    func canvasDidUpdate(_ canvas: CanvasView) {
        // Could update toolbar state (enable/disable undo/redo) here
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        onClose?(self)
    }
}
