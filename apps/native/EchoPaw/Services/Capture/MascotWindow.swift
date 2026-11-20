import AppKit

@MainActor
final class MascotWindow: NSObject, NSWindowDelegate {
    static let title = "EchoPaw Mascot"
    private static let canvasSize = NSSize(width: 512, height: 512)
    private static let keyColor = NSColor(srgbRed: 0, green: 1, blue: 0, alpha: 1)

    private let imageView = CaptureImageView()
    private var panel: CapturePanel?

    var onVisibilityChange: ((Bool) -> Void)?
    var isVisible: Bool { panel?.isVisible == true }

    func show(image: NSImage, chromaKey: Bool) {
        let panel = panel ?? makePanel()
        self.panel = panel
        update(image: image, chromaKey: chromaKey)

        let wasVisible = panel.isVisible
        panel.orderFrontRegardless()
        if panel.isVisible != wasVisible {
            onVisibilityChange?(panel.isVisible)
        }
    }

    func update(image: NSImage, chromaKey: Bool) {
        imageView.image = image
        panel?.isOpaque = chromaKey
        panel?.backgroundColor = chromaKey ? Self.keyColor : .clear
    }

    func hide() {
        guard let panel, panel.isVisible else { return }
        panel.orderOut(nil)
        onVisibilityChange?(false)
    }

    func windowWillClose(_ notification: Notification) {
        onVisibilityChange?(false)
    }

    private func makePanel() -> CapturePanel {
        let panel = CapturePanel(
            contentRect: NSRect(origin: .zero, size: Self.canvasSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = Self.title
        panel.isReleasedWhenClosed = false
        panel.isRestorable = false
        panel.hidesOnDeactivate = false
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        panel.delegate = self

        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.setAccessibilityLabel("Mascot image")
        panel.contentView = imageView
        panel.center()
        assert(panel.contentLayoutRect.size == Self.canvasSize)
        return panel
    }
}

private final class CapturePanel: NSPanel {
    override var canBecomeKey: Bool { true }

    override func performClose(_ sender: Any?) {
        close()
    }

    override func cancelOperation(_ sender: Any?) {
        close()
    }
}

private final class CaptureImageView: NSImageView {
    override var mouseDownCanMoveWindow: Bool { true }
}
