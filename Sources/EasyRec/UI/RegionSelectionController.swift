import AppKit

@MainActor
final class RegionSelectionController {
    private var window: NSWindow?
    private var completion: ((CGRect) -> Void)?
    private var cancellation: (() -> Void)?

    func present(
        on screen: NSScreen, onSelect: @escaping (CGRect) -> Void,
        onCancel: @escaping () -> Void
    ) {
        completion = onSelect
        cancellation = onCancel
        let window = RegionPanel(
            contentRect: screen.frame, styleMask: .borderless,
            backing: .buffered, defer: false)
        window.title = "框选录制区域"
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        let view = RegionSelectionView(frame: NSRect(origin: .zero, size: screen.frame.size))
        view.onSelect = { [weak self] rect in
            guard let self else { return }
            let callback = completion
            dismiss()
            callback?(rect)
        }
        view.onCancel = { [weak self] in self?.cancel() }
        window.contentView = view
        self.window = window
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(view)
        NSApp.activate()
    }

    func cancel() {
        let callback = cancellation
        dismiss()
        callback?()
    }

    func dismiss() {
        window?.orderOut(nil)
        window?.close()
        window = nil
        completion = nil
        cancellation = nil
    }
}

private final class RegionPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

private final class RegionSelectionView: NSView {
    var onSelect: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?
    private var anchor: CGPoint?
    private var selection = CGRect.zero
    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() { addCursorRect(bounds, cursor: .crosshair) }
    override func mouseDown(with event: NSEvent) {
        window?.makeKey()
        anchor = convert(event.locationInWindow, from: nil)
        selection = .zero
        needsDisplay = true
    }
    override func mouseDragged(with event: NSEvent) {
        guard let anchor else { return }
        selection = CaptureRegion.rectangle(
            from: anchor,
            to: convert(event.locationInWindow, from: nil), in: bounds)
        needsDisplay = true
    }
    override func mouseUp(with event: NSEvent) {
        mouseDragged(with: event)
        if selection.width >= 16 && selection.height >= 16 { onSelect?(selection) }
    }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onCancel?() } else { super.keyDown(with: event) }
    }
    override func draw(_ dirtyRect: NSRect) {
        let mask = NSBezierPath(rect: bounds)
        mask.appendRect(selection)
        mask.windingRule = .evenOdd
        NSColor.black.withAlphaComponent(0.35).setFill()
        mask.fill()
        NSColor.white.setStroke()
        let border = NSBezierPath(rect: selection)
        border.lineWidth = 2
        border.stroke()
        let text =
            selection.isEmpty
            ? "拖动框选录制区域 · Esc 取消" : "\(Int(selection.width)) × \(Int(selection.height)) 点 · 松开确认"
        (text as NSString).draw(
            at: NSPoint(x: 24, y: 24),
            withAttributes: [
                .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: NSColor.white,
            ])
    }
}
