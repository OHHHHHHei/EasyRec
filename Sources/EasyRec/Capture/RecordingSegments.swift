import AVFoundation

/// Each pause closes a real MP4. Only a successful final save removes these files.
@MainActor
final class RecordingSegments {
    let destination: URL
    let directory: URL
    private(set) var files: [URL] = []
    private(set) var duration: TimeInterval = 0
    private(set) var bytes = 0

    init(destination: URL) throws {
        self.destination = destination
        directory = destination.deletingPathExtension().appendingPathExtension("segments")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
    }

    var nextURL: URL { directory.appendingPathComponent("part-\(files.count + 1).mp4") }

    func append(_ url: URL, duration: TimeInterval, bytes: Int) {
        files.append(url)
        self.duration += duration.isFinite ? duration : 0
        self.bytes += bytes
    }

    func save() async throws -> URL {
        guard !files.isEmpty else { throw SegmentError.noVideo }
        if files.count == 1 {
            try FileManager.default.moveItem(at: files[0], to: destination)
        } else {
            try await Self.concatenate(files, to: destination)
        }
        // The completed video is already safe; a cleanup failure must not hide it.
        try? FileManager.default.removeItem(at: directory)
        return destination
    }

    static func concatenate(_ files: [URL], to destination: URL) async throws {
        let composition = AVMutableComposition()
        guard
            let video = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid)
        else { throw SegmentError.noVideo }
        var audioTracks: [AVMutableCompositionTrack] = []
        var cursor = CMTime.zero
        for file in files {
            let asset = AVURLAsset(url: file)
            guard let sourceVideo = try await asset.loadTracks(withMediaType: .video).first else {
                throw SegmentError.noVideo
            }
            let range = try await sourceVideo.load(.timeRange)
            guard range.duration.isNumeric, range.duration > .zero else {
                throw SegmentError.noVideo
            }
            if cursor == .zero {
                video.preferredTransform = try await sourceVideo.load(.preferredTransform)
            }
            try video.insertTimeRange(range, of: sourceVideo, at: cursor)
            for (index, sourceAudio) in try await asset.loadTracks(withMediaType: .audio)
                .enumerated()
            {
                if index == audioTracks.count {
                    guard
                        let track = composition.addMutableTrack(
                            withMediaType: .audio,
                            preferredTrackID: kCMPersistentTrackID_Invalid)
                    else { throw SegmentError.exportUnavailable }
                    audioTracks.append(track)
                }
                let audioRange = try await sourceAudio.load(.timeRange).intersection(range)
                if !audioRange.isEmpty {
                    // Keep the original audio offset; empty leading/trailing time stays silent.
                    try audioTracks[index].insertTimeRange(
                        audioRange, of: sourceAudio,
                        at: cursor + audioRange.start - range.start)
                }
            }
            cursor = cursor + range.duration
        }
        guard
            let exporter = AVAssetExportSession(
                asset: composition, presetName: AVAssetExportPresetHighestQuality)
        else {
            throw SegmentError.exportUnavailable
        }
        exporter.videoComposition = try await AVVideoComposition.videoComposition(
            withPropertiesOf: composition)
        // Re-encode joins so samples outside an edit range (for example H.264
        // GOP pre-roll) cannot leak across a pause boundary in other players.
        try await exporter.export(to: destination, as: .mp4)
    }
}

private enum SegmentError: LocalizedError {
    case noVideo, exportUnavailable
    var errorDescription: String? {
        switch self {
        case .noVideo: return "录制片段没有可用的视频画面。"
        case .exportUnavailable: return "无法创建 MP4 导出任务。"
        }
    }
}
