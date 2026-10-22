import AppKit
import SwiftUI

@main
struct EasyRecApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var recorder = RecorderModel.shared

    var body: some Scene {
        MenuBarExtra(
            "EasyRec", systemImage: recorder.phase.isBusy ? "record.circle.fill" : "record.circle"
        ) {
            Text(recorder.phase.title)
            if recorder.phase == .countdown {
                Button("取消倒计时") { recorder.cancelCountdown() }
            }
            if recorder.canStop {
                Text(recorder.formattedDuration)
                Button("停止录制") { Task { await recorder.stop() } }
            }
            Button("显示 EasyRec") { RecorderWindowController.shared.show() }
            if recorder.lastRecording != nil {
                Button("播放上次录制") { recorder.playRecording() }
                Button("在 Finder 中显示上次录制") { recorder.revealRecording() }
            }
            Divider()
            Button("退出") { NSApp.terminate(nil) }
        }
    }
}
