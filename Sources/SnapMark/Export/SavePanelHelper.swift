import AppKit

enum SavePanelHelper {
    static func saveImage(_ image: NSImage, annotations: [Annotation], from window: NSWindow?) {
        guard let rendered = ImageExporter.renderImage(baseImage: image, annotations: annotations),
              let pngData = ImageExporter.pngData(from: rendered) else {
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = defaultFilename()
        panel.canCreateDirectories = true

        let handler: (NSApplication.ModalResponse) -> Void = { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try pngData.write(to: url)
            } catch {
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        }

        if let window = window {
            panel.beginSheetModal(for: window, completionHandler: handler)
        } else {
            let response = panel.runModal()
            handler(response)
        }
    }

    private static func defaultFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return "SnapMark-\(formatter.string(from: Date())).png"
    }
}
