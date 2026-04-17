import AppKit
import CoreGraphics

enum Permissions {
    private static let screenCapturePromptedKey = "screenCapturePrompted"

    static func ensureScreenCaptureAccess() -> Bool {
        if CGPreflightScreenCaptureAccess() {
            UserDefaults.standard.set(false, forKey: screenCapturePromptedKey)
            return true
        }

        let hasPromptedBefore = UserDefaults.standard.bool(forKey: screenCapturePromptedKey)
        let granted = CGRequestScreenCaptureAccess()
        UserDefaults.standard.set(true, forKey: screenCapturePromptedKey)

        if !granted && hasPromptedBefore {
            showPermissionAlert()
        }
        return granted
    }

    static func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "SnapMark needs Screen Recording permission to capture screenshots.\n\nIf you just granted access, quit and reopen SnapMark once, then try again.\n\nYou can manage it in:\nSystem Settings → Privacy & Security → Screen Recording"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
