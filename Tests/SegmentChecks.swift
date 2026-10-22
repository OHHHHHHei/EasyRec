import AVFoundation

@main
struct SegmentChecks {
    @MainActor
    static func main() async throws {
        let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let first = root.appendingPathComponent("first.mp4")
        let silent = root.appendingPathComponent("silent.mp4")
        let second = root.appendingPathComponent("second.mp4")
        let destination = root.appendingPathComponent("joined.mp4")
        try await RecordingSegments.concatenate([first, silent, second], to: destination)
        let asset = AVURLAsset(url: destination)
        let duration = try await asset.load(.duration).seconds
        precondition(abs(duration - 3) < 0.1, "Paused time leaked into exported timeline")
        let videos = try await asset.loadTracks(withMediaType: .video)
        let audios = try await asset.loadTracks(withMediaType: .audio)
        precondition(videos.count == 1 && audios.count == 2, "Video or audio tracks were lost")
        for track in audios {
            let range = try await track.load(.timeRange)
            precondition(range.end.seconds > 2.8, "Audio did not survive the silent middle segment")
        }

        // Passthrough trimming can retain compressed GOP samples outside an edit.
        // Joining those edits must produce a clean timeline for other MP4 players.
        let trimmed = root.appendingPathComponent("trimmed.mp4")
        let edit = AVMutableComposition()
        let source = AVURLAsset(url: first)
        let sourceTrack = try await source.loadTracks(withMediaType: .video)[0]
        let targetTrack = edit.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid)!
        try targetTrack.insertTimeRange(
            CMTimeRange(
                start: .zero,
                duration: CMTime(seconds: 0.7, preferredTimescale: 600)), of: sourceTrack, at: .zero
        )
        let trimExport = AVAssetExportSession(
            asset: edit, presetName: AVAssetExportPresetPassthrough)!
        try await trimExport.export(to: trimmed, as: .mp4)
        let joinedTrim = root.appendingPathComponent("trimmed-joined.mp4")
        try await RecordingSegments.concatenate([trimmed, trimmed], to: joinedTrim)
        let trimDuration = try await AVURLAsset(url: joinedTrim).load(.duration).seconds
        precondition(abs(trimDuration - 1.4) < 0.1)
        let single = try RecordingSegments(destination: root.appendingPathComponent("single.mp4"))
        let part = single.nextURL
        try FileManager.default.copyItem(at: first, to: part)
        single.append(part, duration: 1, bytes: 100)
        let saved = try await single.save()
        precondition(FileManager.default.fileExists(atPath: saved.path))
        precondition(!FileManager.default.fileExists(atPath: single.directory.path))

        let collision = try RecordingSegments(
            destination: root.appendingPathComponent("existing.mp4"))
        try Data("existing recording".utf8).write(to: collision.destination)
        let retained = collision.nextURL
        try FileManager.default.copyItem(at: first, to: retained)
        collision.append(retained, duration: 1, bytes: 100)
        do {
            _ = try await collision.save()
            fatalError("Existing destination was replaced")
        } catch {
            precondition(
                FileManager.default.fileExists(atPath: retained.path),
                "Failed save lost the source segment")
            let original = try String(contentsOf: collision.destination, encoding: .utf8)
            precondition(original == "existing recording")
        }
        print(
            "PASS: Segment concatenation, two audio tracks, silent gap, single-file save and failure preservation"
        )
    }
}
