import AppKit

final class CaptureOverlayWindow: NSWindow {
    var onCaptureComplete: ((CGRect, CGRect) -> Void)?
    var onCancel: (() -> Void)?

    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        self.level = .screenSaver
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.acceptsMouseMovedEvents = true
        self.isReleasedWhenClosed = false

        let overlayView = CaptureOverlayView(frame: CGRect(origin: .zero, size: screen.frame.size))
        self.contentView = overlayView
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
