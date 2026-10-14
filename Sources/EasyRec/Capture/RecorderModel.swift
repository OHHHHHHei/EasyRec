import AVFoundation
import AppKit
import ScreenCaptureKit

/// UI and lifecycle changes run on the main actor. System delegate callbacks
/// hop here and check object identity so a previous session cannot reset a new one.
@MainActor
final class RecorderModel: NSObject, ObservableObject {
    static let shared = RecorderModel()

    @Published private(set) var phase = RecordingPhase.idle
    @Published private(set) var selectedTarget: CaptureTargetKind?
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var fileBytes = 0
    @Published private(set) var lastRecording: URL?
    @Published private(set) var outputDirectory: URL
    @Published var issue: String?
    @Published var systemAudio = true
    @Published var microphone = false
    @Published var showsCursor = true
    @Published var framesPerSecond = 30

    private var filter: SCContentFilter?
    private weak var contentSelectionWindow: NSWindow?
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
    var formattedDuration: String {
        let seconds = Int(max(0, duration))
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds / 60) % 60, seconds % 60)
    }

    func chooseContent(_ target: CaptureTargetKind) {
        guard phase == .idle else { return }
        issue = nil
        // The system picker can hide or deactivate our window. Keep its identity
        // before presenting, because mainWindow may be nil when selection ends.
        contentSelectionWindow = NSApp.mainWindow
        phase = .choosing
        let picker = SCContentSharingPicker.shared
        var configuration = SCContentSharingPickerConfiguration()
        switch target {
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

    func cancelContentSelection() {
        guard phase == .choosing else { return }
        SCContentSharingPicker.shared.isActive = false
        filter = nil
        selectedTarget = nil
        phase = .idle
        returnToRecordingWindow()
    }

    private func returnToRecordingWindow() {
        let window =
            contentSelectionWindow
            ?? NSApp.windows.first { $0.identifier?.rawValue == "main" }
        contentSelectionWindow = nil
        NSApp.unhide(nil)
        if let window {
            if window.isMiniaturized { window.deminiaturize(nil) }
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate()
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

    func start() async {
        guard canStart, let filter else { return }
        issue = nil
        phase = .starting
        var startingStream: SCStream?
        do {
            try FileManager.default.createDirectory(
                at: outputDirectory, withIntermediateDirectories: true)
            let url = nextRecordingURL()
            if microphone {
                let allowed = await AVCaptureDevice.requestAccess(for: .audio)
                guard allowed else { throw CaptureError.microphoneDenied }
            }
            let size = try CaptureGeometry.fit(
                width: filter.contentRect.width, height: filter.contentRect.height,
                scale: Double(filter.pointPixelScale))
            let configuration = SCStreamConfiguration()
            configuration.width = size.width
            configuration.height = size.height
            configuration.minimumFrameInterval = CMTime(value: 1, timescale: Int32(framesPerSecond))
            configuration.queueDepth = 5
            configuration.showsCursor = showsCursor
            configuration.capturesAudio = systemAudio
            configuration.captureMicrophone = microphone
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
            phase = .idle
            return
        }
        do {
            try await failedStream.stopCapture()
            guard stream === failedStream else { return }
            clearSession()
            phase = .idle
        } catch let error as SCStreamError where error.code == .attemptToStopStreamState {
            // The system explicitly confirms that no running capture remains.
            guard stream === failedStream else { return }
            clearSession()
            phase = .idle
        } catch {
            guard stream === failedStream else { return }
            phase = .stopFailed
            issue = "\(message)\n停止采集失败，请点击重试停止：\(error.localizedDescription)"
        }
    }
}

extension RecorderModel: SCContentSharingPickerObserver {
    nonisolated func contentSharingPicker(
        _ picker: SCContentSharingPicker,
        didCancelFor stream: SCStream?
    ) {
        Task { @MainActor [weak self] in
            guard let self, phase == .choosing || phase == .idle else { return }
            phase = .idle
            returnToRecordingWindow()
        }
    }

    nonisolated func contentSharingPicker(
        _ picker: SCContentSharingPicker,
        didUpdateWith filter: SCContentFilter, for stream: SCStream?
    ) {
        Task { @MainActor [weak self] in
            guard let self, phase == .choosing || phase == .idle else { return }
            self.filter = filter
            selectedTarget = filter.style == .display ? .display : .window
            phase = .idle
            returnToRecordingWindow()
        }
    }

    nonisolated func contentSharingPickerStartDidFailWithError(_ error: Error) {
        Task { @MainActor [weak self] in
            guard let self, phase == .choosing || phase == .idle else { return }
            phase = .idle
            issue = "无法选择录制内容：\(error.localizedDescription)"
            returnToRecordingWindow()
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
            let finishedStream = stream
            clearSession()
            phase = .idle
            SCContentSharingPicker.shared.isActive = false
            self.filter = nil
            selectedTarget = nil
            if let finishedStream { try? await finishedStream.stopCapture() }
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
                phase = .idle
                issue = failure
                return
            }
            interruption = error.localizedDescription
            phase = .finishing
        }
    }
}
