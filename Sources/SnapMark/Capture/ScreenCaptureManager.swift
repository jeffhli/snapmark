import AppKit
import CoreGraphics

enum ScreenCaptureManager {
    /// Capture a region of the desktop.
    /// rect is in global NSScreen coordinates (origin bottom-left, y increases upward).
    /// Requires Screen Recording permission granted in System Settings.
    static func capture(rect: CGRect) -> NSImage? {
        guard rect.width > 1, rect.height > 1 else { return nil }

        let desktopBounds = NSScreen.screens.reduce(CGRect.null) { partialResult, screen in
            partialResult.union(screen.frame)
        }
        let captureRect = CGRect(
            x: rect.origin.x,
            y: desktopBounds.maxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )

        guard let cgImage = CGWindowListCreateImage(
            captureRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution]
        ) else {
            return nil
        }

        return NSImage(cgImage: cgImage, size: rect.size)
    }
}
