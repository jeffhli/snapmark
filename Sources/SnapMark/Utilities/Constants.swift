import AppKit
import Carbon

enum Constants {
    // Hotkey: Cmd+Shift+2
    static let hotkeyKeyCode: UInt32 = 0x13  // kVK_ANSI_2
    static let hotkeyModifiers: UInt32 = UInt32(cmdKey | shiftKey)

    // Default annotation settings
    static let defaultStrokeColor = NSColor.systemRed
    static let defaultStrokeWidth: CGFloat = 3.0
    static let defaultFontSize: CGFloat = 18.0
    static let defaultFont = NSFont.systemFont(ofSize: 18.0, weight: .medium)

    // Overlay
    static let overlayDimColor = NSColor.black.withAlphaComponent(0.3)
    static let selectionBorderColor = NSColor.white
    static let selectionBorderWidth: CGFloat = 1.0

    // Editor
    static let toolbarHeight: CGFloat = 48.0
    static let minEditorSize = NSSize(width: 400, height: 350)

    // Undo
    static let maxUndoDepth = 50

    // Blur
    static let defaultBlurRadius: Double = 10.0
}
