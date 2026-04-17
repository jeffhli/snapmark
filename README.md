# SnapMark

A lightweight, high-performance screenshot and annotation tool for macOS. Inspired by [Shottr](https://shottr.cc/).

SnapMark runs as a menu bar app, captures screen regions with a global hotkey, and opens an annotation editor with drawing tools.

## Features

- **Global Hotkey**: Press `⌘⇧2` to start screen capture from anywhere
- **Region Selection**: Click and drag to capture any portion of the screen, with live dimensions display
- **Annotation Tools**:
  - **Rectangle** — Draw bordered rectangles
  - **Arrow** — Draw arrows with arrowheads
  - **Text** — Click to place text annotations
  - **Pen** — Freehand drawing
  - **Highlight** — Semi-transparent highlight overlay
  - **Blur/Pixelate** — Pixelate sensitive areas
- **Select & Move** — Click to select and drag to reposition annotations
- **Undo/Redo** — Full undo history (⌘Z / ⌘⇧Z)
- **Export** — Save as PNG (⌘S) or copy to clipboard (⌘C)
- **Color Picker** — Choose any stroke color
- **Stroke Width** — Adjustable line thickness
- **Lightweight** — Native Swift/AppKit, no Electron, minimal memory footprint
- **Menu Bar App** — Runs in the background, no Dock icon clutter

## Requirements

- macOS 12.0 (Monterey) or later
- Swift 5.9+ (included with Xcode Command Line Tools)

## Build from Source

### 1. Install Xcode Command Line Tools

If you don't already have them:

```bash
xcode-select --install
```

### 2. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/snapmark.git
cd snapmark
```

### 3. Build the App

**Release build** (recommended — creates a `.app` bundle):

```bash
chmod +x scripts/build.sh
./scripts/build.sh
```

This produces `build/SnapMark.app`.

**Debug build** (for development):

```bash
./scripts/run.sh
```

`run.sh` now builds a debug `.app` bundle and opens it, instead of launching the raw SwiftPM executable.

### Stable Signing for Screen Recording Permission

macOS stores **Screen Recording** permission against the app's code signing identity. SnapMark now defaults to signing with the local certificate `SnapMark Local Code Signing`, which keeps the app identity stable across rebuilds on the same machine.

Check that the local signing certificate exists:

```bash
security find-identity -p codesigning -v
```

If that identity is present, `./scripts/build.sh` and `./scripts/run.sh` will use it automatically.

If you want to override the signing identity, you can still set `SIGN_IDENTITY` explicitly:

```bash
SIGN_IDENTITY="Apple Development: Your Name (TEAMID)" ./scripts/build.sh
```

If no matching signing identity is available, the build script falls back to ad-hoc signing. In that mode, macOS may ask for Screen Recording permission again after rebuilds because the app identity is not stable.

For the most reliable behavior, move the signed app to `/Applications` and launch it from there.

### 4. Install

Copy the app to your Applications folder:

```bash
cp -r build/SnapMark.app /Applications/
```

Or just double-click `build/SnapMark.app` to run it directly.

### 5. Grant Permissions

On first launch, macOS will prompt for **Screen Recording** permission. You must grant this for screenshots to work.

If macOS keeps prompting after every rebuild, check whether the app was built with the local signing certificate or fell back to ad-hoc signing. Always launch the `.app` bundle from `build/SnapMark.app`, not the raw binary in `.build/`.

If you missed the prompt:

1. Open **System Settings** → **Privacy & Security** → **Screen Recording**
2. Enable **SnapMark**
3. Restart the app

### 6. Launch at Login (Optional)

To have SnapMark start automatically:

1. Open **System Settings** → **General** → **Login Items**
2. Click **+** and select `SnapMark.app`

## Usage

### Capturing a Screenshot

1. Press **⌘⇧2** (Command + Shift + 2) anywhere
2. A dark overlay appears with a crosshair cursor
3. Click and drag to select the region you want to capture
4. Release the mouse button — the editor window opens with your capture
5. Press **Escape** to cancel

### Annotating

Select a tool from the toolbar at the top of the editor window:

| Tool | Description |
|------|-------------|
| **Select** (cursor icon) | Click to select annotations, drag to move them |
| **Rectangle** | Click and drag to draw a rectangle |
| **Arrow** | Click and drag to draw an arrow |
| **Text** | Click to place a text field, type your text, press Enter |
| **Pen** | Click and drag to draw freehand |
| **Highlight** | Click and drag to create a semi-transparent highlight |
| **Blur** | Click and drag to pixelate a region |

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘⇧2` | Start screen capture (global) |
| `⌘Z` | Undo |
| `⌘⇧Z` | Redo |
| `⌘S` | Save as PNG |
| `⌘C` | Copy to clipboard |
| `Delete` | Delete selected annotation |
| `Escape` | Deselect / cancel |

### Exporting

- **Save**: Press `⌘S` or click the save icon. Choose a location and filename.
- **Copy**: Press `⌘C` or click the copy icon. The annotated image is copied to the clipboard, ready to paste into any app.

### Menu Bar

Click the scissors icon (✂️) in the menu bar for:
- **Capture Region** — Same as pressing ⌘⇧2
- **About SnapMark** — Version info
- **Quit SnapMark** — Exit the app

## Project Structure

```
Sources/SnapMark/
├── main.swift                  # App entry point
├── AppDelegate.swift           # Menu bar setup, capture coordination
├── Capture/
│   ├── HotkeyManager.swift     # Global hotkey (Carbon API)
│   ├── ScreenCaptureManager.swift  # CGWindowListCreateImage wrapper
│   ├── CaptureOverlayWindow.swift  # Fullscreen transparent window
│   └── CaptureOverlayView.swift    # Region selection UI
├── Editor/
│   ├── EditorWindowController.swift  # Annotation window controller
│   ├── CanvasView.swift              # Main drawing canvas
│   └── ToolbarView.swift             # Tool buttons, color, stroke width
├── Annotations/
│   ├── Annotation.swift        # Protocol definition
│   ├── RectangleAnnotation.swift
│   ├── ArrowAnnotation.swift
│   ├── TextAnnotation.swift
│   ├── FreehandAnnotation.swift
│   ├── HighlightAnnotation.swift
│   └── BlurAnnotation.swift
├── History/
│   └── AnnotationHistory.swift  # Undo/redo stack
├── Export/
│   ├── ImageExporter.swift      # Render to PNG, clipboard
│   └── SavePanelHelper.swift    # NSSavePanel wrapper
└── Utilities/
    ├── Constants.swift          # App-wide defaults
    ├── GeometryHelpers.swift    # Math utilities
    └── Permissions.swift        # Screen recording permission
```

## Technical Details

- **Rendering**: All drawing uses Core Graphics for maximum performance
- **Hotkey**: Uses Carbon `RegisterEventHotKey` API for reliable global hotkey registration
- **Capture**: Uses `CGWindowListCreateImage` with `.bestResolution` for Retina support
- **Undo**: Custom snapshot-based undo stack (max 50 states)
- **Multi-monitor**: Creates overlay windows on all connected displays
- **Memory**: Captured images stored as compressed NSImage; annotations are lightweight objects

## Troubleshooting

### Screenshot is blank or shows wrong content
Make sure Screen Recording permission is granted. Restart the app after granting permission.

If the permission prompt appears after every rebuild, do not launch `.build/debug/SnapMark` directly. Launch `build/SnapMark.app` and sign it with `SIGN_IDENTITY="Apple Development: Your Name (TEAMID)"` when building.

### Hotkey doesn't work
Another app may have registered `⌘⇧2`. Check System Settings → Keyboard → Keyboard Shortcuts for conflicts.

### App doesn't appear
SnapMark runs as a menu bar app — look for the scissors icon (✂️) in the menu bar, not the Dock.

## License

MIT License. See [LICENSE](LICENSE) for details.
