import AppKit
import SwiftUI

/// A compact panel stays visible when other apps become active and remains a
/// valid main window for the system content picker and save-folder dialog.
private final class RecorderPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

private final class ToolbarHostingView<Content: View>: NSHostingView<Content> {
    override var isOpaque: Bool { false }
    override var mouseDownCanMoveWindow: Bool { true }
}

@MainActor
final class RecorderWindowController {
    static let shared = RecorderWindowController()
    private(set) var window: NSWindow?
    private init() {}

    func show() {
        if window == nil { window = makeWindow() }
        NSApp.unhide(nil)
        if window?.isMiniaturized == true { window?.deminiaturize(nil) }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    func hide() { window?.orderOut(nil) }

    private func makeWindow() -> NSWindow {
        let size = RecorderAppearance.toolbarSize
        let panel = RecorderPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless], backing: .buffered, defer: false)
        panel.title = "EasyRec"
        panel.identifier = NSUserInterfaceItemIdentifier("main")
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.appearance = NSAppearance(named: .aqua)
        let hostingView = ToolbarHostingView(rootView: RecorderToolbar(recorder: .shared))
        // Clip the native hosting surface too: the glass background can leave
        // a rectangular backing visible outside SwiftUI's rounded shape.
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.layer?.cornerRadius = RecorderAppearance.cornerRadius
        hostingView.layer?.cornerCurve = .continuous
        hostingView.layer?.masksToBounds = true
        panel.contentView = hostingView
        panel.setContentSize(size)
        if !panel.setFrameUsingName("EasyRecToolbar") {
            if let screen = NSScreen.main {
                panel.setFrameOrigin(
                    NSPoint(
                        x: screen.visibleFrame.midX - size.width / 2,
                        y: screen.visibleFrame.maxY - 130))
            } else {
                panel.center()
            }
        }
        panel.setFrameAutosaveName("EasyRecToolbar")
        return panel
    }
}
