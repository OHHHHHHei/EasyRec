import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        RecorderWindowController.shared.show()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    @MainActor
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool)
        -> Bool
    {
        RecorderWindowController.shared.show()
        return false
    }

    @MainActor
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard RecorderModel.shared.phase.isBusy else { return .terminateNow }
        let alert = NSAlert()
        alert.messageText = "请先结束录制"
        alert.informativeText = "点击工具栏或菜单栏中的停止录制，等待文件保存完成后再退出。"
        alert.runModal()
        return .terminateCancel
    }
}
