import AVFoundation
import AppKit
import ScreenCaptureKit

/// UI and lifecycle changes run on the main actor. System delegate callbacks
/// hop here and check object identity so a previous session cannot reset a new one.
@MainActor
final class RecorderModel: NSObject, ObservableObject {
    static let shared = RecorderModel()

    @Published private(set) var phase = RecordingPhase.idle
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var fileBytes = 0
    @Published private(set) var lastRecording: URL?
    @Published private(set) var outputDirectory: URL
    @Published var issue: String?
    @Published var preferences = RecorderPreferences() { didSet { preferences.save() } }
    @Published private(set) var countdownRemaining = 0
    private var countdownTask: Task<Void, Error>?

    @Published private var filter: SCContentFilter?
    @Published private var region: CGRect?
    private let regionSelector = RegionSelectionController()
    private var stream: SCStream?
    private var output: SCRecordingOutput?
    private var destination: URL?
    private var progressTask: Task<Void, Never>?
    private var interruption: String?
    private var failedRecordingIssue: String?
    private static let outputDirectoryKey = "recordingOutputDirectory"

    override private init() {
        if let savedPath = UserDefaults.standard.string(forKey: Self.outputDirectoryKey) {
            outputDirectory = URL(fileURLWithPath: savedPath, isDirectory: true)
        } else {
            let movies =
                FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first
                ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
                    "Movies", isDirectory: true)
            outputDirectory = movies.appendingPathComponent("EasyRec", isDirectory: true)
        }
        super.init()
        SCContentSharingPicker.shared.add(self)
    }

    var canStart: Bool { phase == .idle && filter != nil }
    var canStop: Bool { phase == .recording || phase == .stopFailed }
    var selectedTarget: CaptureTargetKind? {
        filter.map { region != nil ? .region : $0.style == .display ? .display : .window }
    }
    var formattedDuration: String {
        let seconds = Int(max(0, duration))
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds / 60) % 60, seconds % 60)
    }

    func chooseContent(_ target: CaptureTargetKind) {
        guard phase == .idle else { return }
        if target == .region { Task { await chooseRegion() }; return }
        issue = nil
        phase = .choosing
        let picker = SCContentSharingPicker.shared
        var configuration = SCContentSharingPickerConfiguration()
        switch target {
        case .region: return
        case .display: configuration.allowedPickerModes = [.singleDisplay]
        case .window: configuration.allowedPickerModes = [.singleWindow]
        }
        configuration.allowsChangingSelectedContent = false
        configuration.excludedBundleIDs = Bundle.main.bundleIdentifier.map { [$0] } ?? []
        picker.defaultConfiguration = configuration
        picker.maximumStreamCount = 1
        picker.isActive = true
        picker.present()
    }

    private func chooseRegion() async {
        guard phase == .idle else { return }
        phase = .choosingRegion
        issue = nil
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard phase == .choosingRegion else { return }
            RecorderWindowController.shared.hide()
            regionSelector.present { [weak self] displayID, rect in
                guard let self, let display = content.displays.first(where: { $0.displayID == displayID }) else { return }
                let ownApp = content.applications.filter { $0.bundleIdentifier == Bundle.main.bundleIdentifier }
                filter = SCContentFilter(display: display, excludingApplications: ownApp, exceptingWindows: [])
                region = rect
                phase = .idle
                RecorderWindowController.shared.show()
            } onCancel: { [weak self] in
                self?.phase = .idle
                RecorderWindowController.shared.show()
            }
        } catch {
            phase = .idle
            issue = "无法框选区域：\(error.localizedDescription)。请在系统设置中允许屏幕录制。"
            RecorderWindowController.shared.show()
        }
    }

    func cancelContentSelection() {
        guard phase == .choosing else { return }
        SCContentSharingPicker.shared.isActive = false
        filter = nil
        region = nil
        phase = .idle
        RecorderWindowController.shared.show()
    }

    func chooseOutputDirectory(in window: NSWindow?) async {
        guard phase == .idle else { return }
        issue = nil
        phase = .choosingDestination
        defer { if phase == .choosingDestination { phase = .idle } }

        let panel = NSOpenPanel()
        panel.title = "选择录制保存文件夹"
        panel.prompt = "保存到这里"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL =
            FileManager.default.fileExists(atPath: outputDirectory.path)
            ? outputDirectory : outputDirectory.deletingLastPathComponent()
        let response: NSApplication.ModalResponse
        if let window {
            response = await panel.beginSheetModal(for: window)
        } else {
            response = await panel.begin()
        }
        guard response == .OK, let url = panel.url else { return }
        outputDirectory = url.standardizedFileURL
        UserDefaults.standard.set(outputDirectory.path, forKey: Self.outputDirectoryKey)
    }

    func openOutputDirectory() {
        do {
            try FileManager.default.createDirectory(
                at: outputDirectory, withIntermediateDirectories: true)
            NSWorkspace.shared.open(outputDirectory)
        } catch {
            issue = "无法打开保存文件夹：\(error.localizedDescription)"
        }
    }

    private func nextRecordingURL() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        let name = "EasyRec-\(formatter.string(from: Date()))"
        var candidate = outputDirectory.appendingPathComponent(name).appendingPathExtension("mp4")
        var suffix = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = outputDirectory.appendingPathComponent("\(name)-\(suffix)")
                .appendingPathExtension("mp4")
            suffix += 1
        }
        return candidate
    }

    func toggleRecording() async {
        if phase == .countdown { cancelCountdown() }
        else if canStop { await stop() }
        else if canStart { await start() }
        else if phase == .idle { RecorderWindowController.shared.show() }
    }

    func cancelCountdown() {
        guard phase == .countdown else { return }
        countdownTask?.cancel()
        countdownTask = nil
        countdownRemaining = 0
        phase = .idle
    }

    func cancelPreparation() {
        if phase == .countdown { cancelCountdown() }
        else if phase == .choosingRegion { regionSelector.cancel(); phase = .idle }
        else { cancelContentSelection() }
    }

    func start() async {
        guard canStart, let filter else { return }
        issue = nil
        phase = .starting
        var startingStream: SCStream?
        do {
            try FileManager.default.createDirectory(
                at: outputDirectory, withIntermediateDirectories: true)
            let url = nextRecordingURL()
            if preferences.microphone {
                let allowed = await AVCaptureDevice.requestAccess(for: .audio)
                guard allowed else { throw CaptureError.microphoneDenied }
                guard MicrophoneMonitor.device(id: preferences.microphoneDeviceID) != nil else {
                    throw CaptureError.microphoneUnavailable
                }
            }
            if preferences.countdownSeconds > 0 {
                phase = .countdown
                countdownRemaining = preferences.countdownSeconds
                let task = Task { @MainActor in
                    while countdownRemaining > 0 {
                        try await Task.sleep(for: .seconds(1))
                        countdownRemaining -= 1
                    }
                }
                countdownTask = task
                do { try await task.value } catch { return }
                guard !task.isCancelled else { return }
                countdownTask = nil
                phase = .starting
            }
            let size = try CaptureGeometry.fit(
                width: (region ?? filter.contentRect).width, height: (region ?? filter.contentRect).height,
                scale: Double(filter.pointPixelScale))
            let configuration = SCStreamConfiguration()
            if let region { configuration.sourceRect = region }
            configuration.width = size.width
            configuration.height = size.height
            configuration.minimumFrameInterval = CMTime(value: 1, timescale: Int32(preferences.framesPerSecond))
            configuration.queueDepth = 5
            configuration.showsCursor = preferences.showsCursor
            configuration.capturesAudio = preferences.systemAudio
            configuration.captureMicrophone = preferences.microphone
            configuration.microphoneCaptureDeviceID = preferences.microphoneDeviceID.isEmpty ? nil : preferences.microphoneDeviceID
            configuration.excludesCurrentProcessAudio = true
            configuration.sampleRate = 48_000
            configuration.channelCount = 2

            let recordingConfiguration = SCRecordingOutputConfiguration()
            recordingConfiguration.outputURL = url
            recordingConfiguration.outputFileType = .mp4
            recordingConfiguration.videoCodecType = .h264
            let recordingOutput = SCRecordingOutput(
                configuration: recordingConfiguration, delegate: self)
            let captureStream = SCStream(
                filter: filter, configuration: configuration, delegate: self)
            // Attach before startCapture so the first captured frame reaches the file.
            try captureStream.addRecordingOutput(recordingOutput)
            self.stream = captureStream
            startingStream = captureStream
            self.output = recordingOutput
            destination = url
            interruption = nil
            duration = 0
            fileBytes = 0
            try await captureStream.startCapture()
            // Actual 'recording' state is set only by didStartRecording.
        } catch {
            // A delegate may have already finished this session while startCapture
            // was suspended. Do not clear a different, newly started session.
            if let startingStream, stream !== startingStream { return }
            await finishFailedCapture(message: "启动失败：\(error.localizedDescription)")
        }
    }

    func stop() async {
        guard canStop, let stream else { return }
        if let failure = failedRecordingIssue {
            await finishFailedCapture(message: failure)
            return
        }
        phase = .finishing
        do {
            try await stream.stopCapture()
            // Keep stream/output alive until didFinishRecording has finalized the MP4.
        } catch {
            // A failed stop can leave the capture running. Keep the Stop action available.
            guard self.stream === stream else { return }
            phase = .stopFailed
            issue = "停止请求失败，请重试：\(error.localizedDescription)"
        }
    }

    func revealRecording() {
        if let lastRecording { NSWorkspace.shared.activateFileViewerSelecting([lastRecording]) }
    }

    func playRecording() {
        if let lastRecording { NSWorkspace.shared.open(lastRecording) }
    }

    private func clearSession() {
        progressTask?.cancel()
        progressTask = nil
        output = nil
        stream = nil
        destination = nil
        failedRecordingIssue = nil
        phase = .idle
    }

    /// Output failure does not imply that capture has stopped. Keep the stream
    /// and block a new recording until stop succeeds; expose retry on failure.
    private func finishFailedCapture(message: String) async {
        guard phase != .finishing || failedRecordingIssue == nil else { return }
        failedRecordingIssue = message
        progressTask?.cancel()
        phase = .finishing
        issue = message
        guard let failedStream = stream else {
            clearSession()
            return
        }
        do {
            try await failedStream.stopCapture()
        } catch let error as SCStreamError where error.code == .attemptToStopStreamState {
            // The system explicitly confirms that no running capture remains.
        } catch {
            guard stream === failedStream else { return }
            phase = .stopFailed
            issue = "\(message)\n停止采集失败，请点击重试停止：\(error.localizedDescription)"
            return
        }
        guard stream === failedStream else { return }
        clearSession()
    }
}

extension RecorderModel: SCContentSharingPickerObserver {
    nonisolated func contentSharingPicker(
        _ picker: SCContentSharingPicker,
        didCancelFor stream: SCStream?
    ) {
        Task { @MainActor [weak self] in
            self?.cancelContentSelection()
        }
    }

    nonisolated func contentSharingPicker(
        _ picker: SCContentSharingPicker,
        didUpdateWith filter: SCContentFilter, for stream: SCStream?
    ) {
        Task { @MainActor [weak self] in
            guard let self, phase == .choosing else { return }
            self.filter = filter
            region = nil
            phase = .idle
            RecorderWindowController.shared.show()
        }
    }

    nonisolated func contentSharingPickerStartDidFailWithError(_ error: Error) {
        Task { @MainActor [weak self] in
            guard let self, phase == .choosing else { return }
            phase = .idle
            issue = "无法选择录制内容：\(error.localizedDescription)"
            RecorderWindowController.shared.show()
        }
    }
}

extension RecorderModel: SCRecordingOutputDelegate {
    nonisolated func recordingOutputDidStartRecording(_ recordingOutput: SCRecordingOutput) {
        Task { @MainActor [weak self] in
            guard let self, output === recordingOutput, phase == .starting else { return }
            phase = .recording
            progressTask = Task { @MainActor [weak self] in
                while !Task.isCancelled {
                    guard let self, let output else { return }
                    let seconds = output.recordedDuration.seconds
                    if seconds.isFinite { duration = seconds }
                    fileBytes = output.recordedFileSize
                    do { try await Task.sleep(for: .seconds(1)) } catch { return }
                }
            }
        }
    }

    nonisolated func recordingOutputDidFinishRecording(_ recordingOutput: SCRecordingOutput) {
        Task { @MainActor [weak self] in
            guard let self, output === recordingOutput, failedRecordingIssue == nil else { return }
            lastRecording = destination
            let seconds = recordingOutput.recordedDuration.seconds
            if seconds.isFinite { duration = seconds }
            fileBytes = recordingOutput.recordedFileSize
            issue = interruption.map { "录制已中断，已保存结束前的内容：\($0)" }
            // We never detach the output or reconfigure a running stream. Stop
            // requests (or stream termination) finish the file; do not stop twice.
            clearSession()
            SCContentSharingPicker.shared.isActive = false
            self.filter = nil
            region = nil
        }
    }

    nonisolated func recordingOutput(
        _ recordingOutput: SCRecordingOutput, didFailWithError error: Error
    ) {
        Task { @MainActor [weak self] in
            guard let self, output === recordingOutput else { return }
            await finishFailedCapture(
                message: "保存失败：\(error.localizedDescription)。本次文件可能不完整，请重新录制。")
        }
    }
}

extension RecorderModel: SCStreamDelegate {
    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        Task { @MainActor [weak self] in
            guard let self, self.stream === stream else { return }
            if let failure = failedRecordingIssue {
                clearSession()
                issue = failure
                return
            }
            interruption = error.localizedDescription
            phase = .finishing
        }
    }
}
