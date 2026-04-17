import AppKit
import CoreGraphics

enum ScreenCaptureManager {
    static func capture(rect: CGRect) -> NSImage? {
        guard rect.width > 1, rect.height > 1 else { return nil }

        guard let cgImage = CGWindowListCreateImage(
            rect,
            .optionOnScreenBelowWindow,
            kCGNullWindowID,
            [.bestResolution]
        ) else {
            return nil
        }

        let image = NSImage(cgImage: cgImage, size: NSSize(width: rect.width, height: rect.height))
        return image
    }
}
