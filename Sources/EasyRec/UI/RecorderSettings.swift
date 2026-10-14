import SwiftUI

struct RecorderSettings: View {
    @ObservedObject var recorder: RecorderModel
    let chooseFolder: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("设置").font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("MP4").font(.system(size: 10)).foregroundStyle(.secondary)
            }
            Divider()
            HStack {
                Text("帧率")
                Spacer()
                Picker("帧率", selection: $recorder.framesPerSecond) {
                    Text("30 fps").tag(30)
                    Text("60 fps").tag(60)
                }
                .labelsHidden().pickerStyle(.segmented).frame(width: 152)
            }
            Toggle("显示鼠标指针", isOn: $recorder.showsCursor).toggleStyle(.switch)
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
