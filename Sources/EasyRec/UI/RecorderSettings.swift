import SwiftUI

struct RecorderSettings: View {
    @ObservedObject var recorder: RecorderModel
    @ObservedObject private var shortcuts = RecordingShortcuts.shared
    let chooseFolder: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("设置").font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("MP4").font(.system(size: 10)).foregroundStyle(.secondary)
            }
            Button("框选录制区域…") { recorder.chooseContent(.region) }
            Divider()
            HStack {
                Text("帧率")
                Spacer()
                Picker("帧率", selection: $recorder.preferences.framesPerSecond) {
                    Text("30 fps").tag(30)
                    Text("60 fps").tag(60)
                }
                .labelsHidden().pickerStyle(.segmented).frame(width: 152)
            }
            Picker("开始倒计时", selection: $recorder.preferences.countdownSeconds) {
                Text("关闭").tag(0)
                Text("3 秒").tag(3)
                Text("5 秒").tag(5)
            }
            .pickerStyle(.segmented)
            Toggle("显示鼠标指针", isOn: $recorder.preferences.showsCursor).toggleStyle(.switch)
            MicrophoneSettings(recorder: recorder)
            Text("⌘⇧R 开始／停止　⌘⇧E 显示／隐藏")
                .font(.system(size: 10)).foregroundStyle(.secondary)
            if !shortcuts.unavailable.isEmpty {
                Text("快捷键被占用：" + shortcuts.unavailable.joined(separator: "、"))
                    .font(.system(size: 10)).foregroundStyle(.orange)
            }
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Label("保存位置", systemImage: "folder").fontWeight(.medium)
                Text(recorder.outputDirectory.path)
                    .font(.system(size: 10)).foregroundStyle(.secondary)
                    .lineLimit(2).textSelection(.enabled).help(recorder.outputDirectory.path)
                HStack {
                    Button("选择文件夹…", action: chooseFolder)
                    Button("打开文件夹") { recorder.openOutputDirectory() }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(size: 12)).controlSize(.small)
        .padding(18).frame(width: 304)
        .background(.white)
        .disabled(recorder.phase != .idle)
    }
}
