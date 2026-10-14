import SwiftUI

struct RecorderToolbar: View {
    @ObservedObject var recorder: RecorderModel
    @ViewState private var showsSettings = false
    @ViewState private var showsIssue = false
    private var canConfigure: Bool { recorder.phase == .idle }

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 8) {
                Image(systemName: "circle.grid.2x3.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary.opacity(0.55))
                    .frame(width: 8).help("拖动工具栏")
                ToolbarTile("屏幕", icon: "display", selected: recorder.selectedTarget == .display) {
                    recorder.chooseContent(.display)
                }
                .disabled(!canConfigure).help("选择要录制的显示器")
                ToolbarTile("窗口", icon: "macwindow", selected: recorder.selectedTarget == .window) {
                    recorder.chooseContent(.window)
                }
                .disabled(!canConfigure).help("选择要录制的应用窗口")
                toolbarDivider
                ToolbarTile("系统音", icon: "waveform", selected: recorder.systemAudio) {
                    recorder.systemAudio.toggle()
                }
                .disabled(!canConfigure)
                .help(recorder.systemAudio ? "系统声音已开启，点击关闭" : "系统声音已关闭，点击开启")
                ToolbarTile(
                    "麦克风", icon: recorder.microphone ? "mic.fill" : "mic.slash",
                    selected: recorder.microphone
                ) {
                    recorder.microphone.toggle()
                }
                .disabled(!canConfigure)
                .help(recorder.microphone ? "麦克风已开启，点击关闭" : "麦克风已关闭，点击开启")
                toolbarDivider
                Spacer(minLength: 0)
                recordButton
                Button {
                    showsSettings.toggle()
                } label: {
                    Image(systemName: showsSettings ? "gearshape.fill" : "gearshape")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 26, height: 32).contentShape(Rectangle())
                }
                .buttonStyle(.plain).foregroundStyle(.primary.opacity(0.8))
                .accessibilityLabel("设置").help("保存位置、帧率与鼠标指针")
                .popover(isPresented: $showsSettings, arrowEdge: .bottom) {
                    RecorderSettings(recorder: recorder) {
                        showsSettings = false
                        let window = RecorderWindowController.shared.window
                        Task { await recorder.chooseOutputDirectory(in: window) }
                    }
                    .preferredColorScheme(.light)
                    .presentationBackground(.white)
                }
                Button {
                    RecorderWindowController.shared.hide()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 20, height: 32).contentShape(Rectangle())
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
                .accessibilityLabel("隐藏工具栏")
                .help("隐藏工具栏；仍可从菜单栏显示或停止录制")
            }
            .frame(height: 44)
            statusLine.frame(height: 14).padding(.leading, 17).padding(.trailing, 4)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(
            width: RecorderAppearance.toolbarSize.width,
            height: RecorderAppearance.toolbarSize.height
        )
        .background { RecorderBackground() }
        .clipShape(RecorderAppearance.toolbarShape)
        .preferredColorScheme(.light)
        .onExitCommand { recorder.cancelContentSelection() }
    }

    private var toolbarDivider: some View {
        Rectangle().fill(.black.opacity(0.1))
            .frame(width: 1, height: 25).padding(.horizontal, 4)
    }

    private var recordButton: some View {
        Button {
            Task {
                if recorder.canStop { await recorder.stop() } else { await recorder.start() }
            }
        } label: {
            HStack(spacing: 6) {
                if recorder.phase == .starting || recorder.phase == .finishing {
                    ProgressView().controlSize(.mini).scaleEffect(0.8)
                } else {
                    Image(systemName: recorder.canStop ? "stop.fill" : "record.circle.fill")
                        .font(.system(size: 13))
                }
                Text(recorder.phase == .stopFailed ? "重试" : recorder.canStop ? "停止" : "录制")
                    .font(.system(size: 12, weight: .semibold))
            }
            .frame(width: 76, height: 32).foregroundStyle(.white)
            .background(RecorderAppearance.recordColor, in: RoundedRectangle(cornerRadius: 9))
            .opacity(recorder.canStart || recorder.canStop ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(!recorder.canStart && !recorder.canStop)
        .accessibilityLabel(recorder.canStop ? "停止并保存" : "开始录制")
        .help(recorder.canStart ? "开始录制" : recorder.canStop ? "停止并保存" : "先选择屏幕或窗口")
    }

    private var statusLine: some View {
        HStack(spacing: 5) {
            if let issue = recorder.issue {
                Button {
                    showsIssue = true
                } label: {
                    Label("录制出现问题 · 查看详情", systemImage: "exclamationmark.circle")
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain).help(issue)
                .popover(isPresented: $showsIssue, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(issue).textSelection(.enabled)
                        Button("知道了") {
                            showsIssue = false
                            recorder.issue = nil
                        }
                    }
                    .font(.system(size: 12)).padding(16).frame(width: 300)
                }
            } else {
                Circle()
                    .fill(
                        recorder.canStop
                            ? Color.red
                            : recorder.canStart || recorder.lastRecording != nil
                                ? Color.green : Color.secondary.opacity(0.55)
                    )
                    .frame(width: 4, height: 4)
                Text(statusText).lineLimit(1)
            }
            Spacer(minLength: 4)
            if recorder.phase == .choosing {
                Button("取消") { recorder.cancelContentSelection() }.buttonStyle(.plain)
            } else if recorder.canStop {
                Text(
                    ByteCountFormatter.string(
                        fromByteCount: Int64(recorder.fileBytes), countStyle: .file)
                )
                .monospacedDigit()
            } else if recorder.lastRecording != nil && canConfigure {
                Button("播放") { recorder.playRecording() }.buttonStyle(.plain)
                Button("文件") { recorder.revealRecording() }.buttonStyle(.plain)
            }
        }
        .font(.system(size: 10)).foregroundStyle(.secondary)
    }

    private var statusText: String {
        switch recorder.phase {
        case .choosing: return "选择要共享的屏幕或窗口…"
        case .choosingDestination: return "选择保存文件夹…"
        case .starting: return "正在启动…"
        case .recording: return recorder.formattedDuration
        case .finishing: return "正在保存…"
        case .stopFailed: return "停止失败，请重试"
        case .idle:
            if recorder.canStart { return recorder.selectedTarget == .display ? "屏幕已就绪" : "窗口已就绪" }
            return recorder.lastRecording != nil ? "录制已保存" : "选择屏幕或窗口，开始录制"
        }
    }
}
