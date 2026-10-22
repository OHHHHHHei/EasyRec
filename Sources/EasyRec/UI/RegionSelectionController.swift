import AppKit

@MainActor
final class RegionSelectionController {
    private var windows: [NSWindow] = []
    private var completion: ((CGDirectDisplayID, CGRect) -> Void)?
    private var cancellation: (() -> Void)?

    func present(onSelect: @escaping (CGDirectDisplayID, CGRect) -> Void,
                 onCancel: @escaping () -> Void) {
        completion = onSelect
        cancellation = onCancel
        for screen in NSScreen.screens {
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { continue }
            let window = RegionPanel(contentRect: screen.frame, styleMask: .borderless,
                backing: .buffered, defer: false)
            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.isReleasedWhenClosed = false
            let view = RegionSelectionView(frame: NSRect(origin: .zero, size: screen.frame.size))
            view.onSelect = { [weak self] rect in
                guard let self else { return }
                let callback = completion
                close()
                callback?(number.uint32Value, rect)
            }
            view.onCancel = { [weak self] in self?.cancel() }
            window.contentView = view
            windows.append(window)
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(view)
        }
        NSApp.activate()
    }

    func cancel() {
        let callback = cancellation
        close()
        callback?()
    }

    private func close() {
        windows.forEach { $0.orderOut(nil); $0.close() }
        windows.removeAll()
        completion = nil
        cancellation = nil
    }
}

private final class RegionPanel: NSPanel {
    override var canBecomeKey: Bool { true }
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
        selection = CaptureRegion.rectangle(from: anchor,
            to: convert(event.locationInWindow, from: nil), in: bounds)
        needsDisplay = true
    }
    override func mouseUp(with event: NSEvent) {
        mouseDragged(with: event)
        if selection.width >= 16 && selection.height >= 16 { onSelect?(selection) }
    }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onCancel?() }
        else { super.keyDown(with: event) }
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
        let text = selection.isEmpty ? "拖动框选录制区域 · Esc 取消" : "\(Int(selection.width)) × \(Int(selection.height)) 点 · 松开确认"
        (text as NSString).draw(at: NSPoint(x: 24, y: 24), withAttributes: [
            .font: NSFont.systemFont(ofSize: 18, weight: .semibold), .foregroundColor: NSColor.white])
    }
}
