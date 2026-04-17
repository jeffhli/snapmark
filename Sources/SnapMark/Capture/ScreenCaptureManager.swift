import AppKit
import CoreGraphics

enum ScreenCaptureManager {
    /// Capture a region of a specific screen.
    /// rect is in global NSScreen coordinates (origin bottom-left, y increases upward).
    /// Requires Screen Recording permission granted in System Settings.
    static func capture(rect: CGRect, on screen: NSScreen) -> NSImage? {
        guard rect.width > 1, rect.height > 1 else { return nil }
        guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }

        let scaleFactor = screen.backingScaleFactor
        let localRect = CGRect(
            x: rect.origin.x - screen.frame.origin.x,
            y: rect.origin.y - screen.frame.origin.y,
            width: rect.width,
            height: rect.height
        )
        let displayRect = CGRect(
            x: localRect.origin.x * scaleFactor,
            y: (screen.frame.height - localRect.origin.y - localRect.height) * scaleFactor,
            width: localRect.width * scaleFactor,
            height: localRect.height * scaleFactor
        ).integral

        guard let cgImage = CGDisplayCreateImage(CGDirectDisplayID(screenNumber.uint32Value), rect: displayRect) else {
            return nil
        }

        return NSImage(cgImage: cgImage, size: rect.size)
    }
}
