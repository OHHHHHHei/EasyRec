import AVFoundation
import SwiftUI

struct MicrophoneSettings: View {
    @ObservedObject var recorder: RecorderModel
    @StateObject private var monitor = MicrophoneMonitor()
    @ViewState private var testing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("麦克风", selection: $recorder.preferences.microphoneDeviceID) {
                Text("系统默认").tag("")
                ForEach(monitor.devices, id: \.uniqueID) { device in
                    Text(device.localizedName).tag(device.uniqueID)
                }
                if !recorder.preferences.microphoneDeviceID.isEmpty
                    && !monitor.devices.contains(where: {
                        $0.uniqueID == recorder.preferences.microphoneDeviceID
                    })
                {
                    Text("已选设备未连接").tag(recorder.preferences.microphoneDeviceID)
                }
            }
            HStack {
                Button(testing ? "停止测试" : "测试麦克风") { testing.toggle() }
                ProgressView(value: monitor.level).tint(.green)
                    .accessibilityLabel("麦克风输入音量")
            }
            if let message = monitor.message {
                Text(message).font(.caption).foregroundStyle(.orange)
            }
            Text("测试仅显示输入音量，不保存声音。")
                .font(.caption).foregroundStyle(.secondary)
        }
        .task { monitor.refreshDevices() }
        .task(id: testing) {
            if testing { await monitor.run(deviceID: recorder.preferences.microphoneDeviceID) }
        }
        .onChange(of: recorder.preferences.microphoneDeviceID) { testing = false }
        .onChange(of: recorder.phase) { if recorder.phase != .idle { testing = false } }
        .onReceive(
            NotificationCenter.default.publisher(for: AVCaptureDevice.wasConnectedNotification)
        ) { _ in monitor.refreshDevices() }
        .onReceive(
            NotificationCenter.default.publisher(for: AVCaptureDevice.wasDisconnectedNotification)
        ) { _ in monitor.refreshDevices() }
        .disabled(recorder.phase != .idle)
    }
}
