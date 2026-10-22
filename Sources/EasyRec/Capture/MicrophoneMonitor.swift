@preconcurrency import AVFoundation

@MainActor
final class MicrophoneMonitor: ObservableObject {
    @Published private(set) var devices: [AVCaptureDevice] = []
    @Published private(set) var level: Double = 0
    @Published private(set) var message: String?
    private let queue = DispatchQueue(label: "EasyRec.microphone-preview")

    func refreshDevices() {
        devices =
            AVCaptureDevice.DiscoverySession(
                deviceTypes: [.microphone, .external],
                mediaType: .audio, position: .unspecified
            ).devices
    }

    static func device(id: String) -> AVCaptureDevice? {
        id.isEmpty ? AVCaptureDevice.default(for: .audio) : AVCaptureDevice(uniqueID: id)
    }

    /// Runs only while the user has explicitly enabled the test in the popover.
    /// Samples are metered in memory, never saved or played through the speakers.
    func run(deviceID: String) async {
        message = nil
        guard await AVCaptureDevice.requestAccess(for: .audio) else {
            message = "请在系统设置中允许麦克风访问。"
            return
        }
        guard !Task.isCancelled else { return }
        guard let device = Self.device(id: deviceID) else {
            message = "麦克风已断开，请重新选择。"
            return
        }
        let session = AVCaptureSession()
        do {
            let input = try AVCaptureDeviceInput(device: device)
            let output = AVCaptureAudioDataOutput()
            guard session.canAddInput(input), session.canAddOutput(output) else {
                message = "无法打开该麦克风。"
                return
            }
            session.addInput(input)
            session.addOutput(output)
            await withCheckedContinuation { continuation in
                queue.async {
                    session.startRunning()
                    continuation.resume()
                }
            }
            defer {
                queue.async { session.stopRunning() }
                level = 0
            }
            while !Task.isCancelled {
                guard device.isConnected, session.isRunning else {
                    message = "麦克风已断开或不可用。"
                    return
                }
                let decibels =
                    output.connection(with: .audio)?.audioChannels.map(\.averagePowerLevel).max()
                    ?? -60
                level = min(1, max(0, (Double(decibels) + 60) / 60))
                try await Task.sleep(for: .milliseconds(100))
            }
        } catch is CancellationError {
            // Closing the popover or starting a recording ends the preview.
        } catch {
            message = error.localizedDescription
        }
    }
}
