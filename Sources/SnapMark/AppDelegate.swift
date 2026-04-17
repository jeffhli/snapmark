import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var hotkeyManager: HotkeyManager!
    private var captureWindows: [CaptureOverlayWindow] = []
    private var editorControllers: [EditorWindowController] = []

    public override init() {
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusBar()
        hotkeyManager = HotkeyManager(onTrigger: { [weak self] in
            self?.startCapture()
        })
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            if let img = NSImage(systemSymbolName: "scissors", accessibilityDescription: "SnapMark") {
                img.isTemplate = true
                button.image = img
            } else {
                button.title = "SM"
            }
        }
        let menu = NSMenu()
        menu.addItem(withTitle: "Capture Region", action: #selector(captureMenuAction), keyEquivalent: "")
            .target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "About SnapMark", action: #selector(showAbout), keyEquivalent: "")
            .target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit SnapMark", action: #selector(quitApp), keyEquivalent: "q")
            .target = self
        statusItem.menu = menu
    }

    @objc private func captureMenuAction() {
        startCapture()
    }

    func startCapture() {
        guard Permissions.ensureScreenCapturePermission() else {
            Permissions.showPermissionAlert()
            return
        }

        // Close any existing overlays
        dismissOverlays()

        // Activate the app so we receive mouse events
        NSApp.activate(ignoringOtherApps: true)

        // Create one overlay per screen
        for screen in NSScreen.screens {
            let window = CaptureOverlayWindow(screen: screen)
            window.onCaptureComplete = { [weak self] rect, screenFrame in
                self?.finishCapture(rect: rect, screenFrame: screenFrame)
            }
            window.onCancel = { [weak self] in
                self?.dismissOverlays()
            }
            captureWindows.append(window)
            window.makeKeyAndOrderFront(nil)
        }
    }

    private func dismissOverlays() {
        for window in captureWindows {
            window.close()
        }
        captureWindows.removeAll()
    }

    private func finishCapture(rect: CGRect, screenFrame: CGRect) {
        // Dismiss overlays FIRST so they don't appear in the screenshot
        dismissOverlays()

        // Convert from NSScreen coordinates (bottom-left origin) to CG display coordinates (top-left origin)
        let primaryHeight = NSScreen.screens.first?.frame.height ?? screenFrame.height
        let cgRect = CGRect(
            x: rect.origin.x,
            y: primaryHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )

        // Small delay to ensure overlay windows are fully removed from screen
        // before we take the screenshot
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self = self else { return }
            guard let image = ScreenCaptureManager.capture(rect: cgRect) else {
                return
            }

            let controller = EditorWindowController(image: image)
            controller.onClose = { [weak self] closedController in
                self?.editorControllers.removeAll { $0 === closedController }
            }
            self.editorControllers.append(controller)
            controller.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "SnapMark"
        alert.informativeText = "A lightweight screenshot and annotation tool for macOS.\n\nVersion 1.0.0\n\nShortcut: ⌘⇧2"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
