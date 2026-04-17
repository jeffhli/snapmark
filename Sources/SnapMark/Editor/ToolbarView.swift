import AppKit

final class ToolbarView: NSView {
    weak var delegate: ToolbarDelegate?

    private var toolButtons: [AnnotationTool: NSButton] = [:]
    private var colorWell: NSColorWell!
    private var strokeSlider: NSSlider!
    private var currentTool: AnnotationTool = .rectangle

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.95).cgColor

        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 4
        stackView.alignment = .centerY
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 32),
        ])

        // Tool buttons
        for tool in AnnotationTool.allCases {
            let button = createToolButton(tool: tool)
            toolButtons[tool] = button
            stackView.addArrangedSubview(button)
        }

        // Separator
        let sep1 = createSeparator()
        stackView.addArrangedSubview(sep1)

        // Color well
        colorWell = NSColorWell(frame: CGRect(x: 0, y: 0, width: 28, height: 28))
        colorWell.color = Constants.defaultStrokeColor
        colorWell.target = self
        colorWell.action = #selector(colorChanged)
        colorWell.translatesAutoresizingMaskIntoConstraints = false
        colorWell.widthAnchor.constraint(equalToConstant: 28).isActive = true
        colorWell.heightAnchor.constraint(equalToConstant: 28).isActive = true
        stackView.addArrangedSubview(colorWell)

        // Stroke width slider
        strokeSlider = NSSlider(value: Double(Constants.defaultStrokeWidth),
                                minValue: 1, maxValue: 20,
                                target: self, action: #selector(strokeWidthChanged))
        strokeSlider.translatesAutoresizingMaskIntoConstraints = false
        strokeSlider.widthAnchor.constraint(equalToConstant: 80).isActive = true
        stackView.addArrangedSubview(strokeSlider)

        // Separator
        let sep2 = createSeparator()
        stackView.addArrangedSubview(sep2)

        // Action buttons
        let undoBtn = createActionButton(symbolName: "arrow.uturn.backward", action: #selector(undoAction), tooltip: "Undo (⌘Z)")
        let redoBtn = createActionButton(symbolName: "arrow.uturn.forward", action: #selector(redoAction), tooltip: "Redo (⌘⇧Z)")
        stackView.addArrangedSubview(undoBtn)
        stackView.addArrangedSubview(redoBtn)

        let sep3 = createSeparator()
        stackView.addArrangedSubview(sep3)

        let copyBtn = createActionButton(symbolName: "doc.on.doc", action: #selector(copyAction), tooltip: "Copy (⌘C)")
        let saveBtn = createActionButton(symbolName: "square.and.arrow.down", action: #selector(saveAction), tooltip: "Save (⌘S)")
        stackView.addArrangedSubview(copyBtn)
        stackView.addArrangedSubview(saveBtn)

        // Flexible space
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stackView.addArrangedSubview(spacer)

        updateToolSelection()
    }

    private func createToolButton(tool: AnnotationTool) -> NSButton {
        let button = NSButton(frame: .zero)
        button.bezelStyle = .toolbar
        button.isBordered = true
        if let img = NSImage(systemSymbolName: tool.sfSymbolName, accessibilityDescription: tool.rawValue) {
            button.image = img
        } else {
            button.title = String(tool.rawValue.prefix(3))
        }
        button.toolTip = tool.rawValue
        button.target = self
        button.action = #selector(toolSelected(_:))
        button.tag = AnnotationTool.allCases.firstIndex(of: tool)!
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 32).isActive = true
        button.heightAnchor.constraint(equalToConstant: 28).isActive = true
        return button
    }

    private func createActionButton(symbolName: String, action: Selector, tooltip: String) -> NSButton {
        let button = NSButton(frame: .zero)
        button.bezelStyle = .toolbar
        button.isBordered = true
        if let img = NSImage(systemSymbolName: symbolName, accessibilityDescription: tooltip) {
            button.image = img
        }
        button.toolTip = tooltip
        button.target = self
        button.action = action
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 32).isActive = true
        button.heightAnchor.constraint(equalToConstant: 28).isActive = true
        return button
    }

    private func createSeparator() -> NSView {
        let sep = NSView()
        sep.wantsLayer = true
        sep.layer?.backgroundColor = NSColor.separatorColor.cgColor
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.widthAnchor.constraint(equalToConstant: 1).isActive = true
        sep.heightAnchor.constraint(equalToConstant: 20).isActive = true
        return sep
    }

    private func updateToolSelection() {
        for (tool, button) in toolButtons {
            button.state = tool == currentTool ? .on : .off
            if tool == currentTool {
                button.bezelColor = NSColor.controlAccentColor.withAlphaComponent(0.3)
            } else {
                button.bezelColor = nil
            }
        }
    }

    // MARK: - Actions

    @objc private func toolSelected(_ sender: NSButton) {
        let allTools = AnnotationTool.allCases
        guard sender.tag < allTools.count else { return }
        currentTool = allTools[sender.tag]
        updateToolSelection()
        delegate?.toolbarDidSelectTool(currentTool)
    }

    @objc private func colorChanged() {
        delegate?.toolbarDidChangeColor(colorWell.color)
    }

    @objc private func strokeWidthChanged() {
        delegate?.toolbarDidChangeStrokeWidth(CGFloat(strokeSlider.doubleValue))
    }

    @objc private func undoAction() { delegate?.toolbarDidRequestUndo() }
    @objc private func redoAction() { delegate?.toolbarDidRequestRedo() }
    @objc private func copyAction() { delegate?.toolbarDidRequestCopy() }
    @objc private func saveAction() { delegate?.toolbarDidRequestSave() }
}

protocol ToolbarDelegate: AnyObject {
    func toolbarDidSelectTool(_ tool: AnnotationTool)
    func toolbarDidChangeColor(_ color: NSColor)
    func toolbarDidChangeStrokeWidth(_ width: CGFloat)
    func toolbarDidRequestUndo()
    func toolbarDidRequestRedo()
    func toolbarDidRequestCopy()
    func toolbarDidRequestSave()
}
