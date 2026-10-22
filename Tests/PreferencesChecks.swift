import Foundation

@main
struct PreferencesChecks {
    static func main() {
        let name = "EasyRec.Tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        var settings = RecorderPreferences(defaults: defaults)
        precondition(settings.systemAudio && !settings.microphone && settings.showsCursor)
        precondition(settings.framesPerSecond == 30 && settings.countdownSeconds == 3)
        settings.systemAudio = false
        settings.microphone = true
        settings.showsCursor = false
        settings.framesPerSecond = 60
        settings.countdownSeconds = 0
        settings.microphoneDeviceID = "test-external-microphone"
        settings.save(to: defaults)
        precondition(RecorderPreferences(defaults: defaults) == settings)
        defaults.set(120, forKey: "framesPerSecond")
        defaults.set(-1, forKey: "countdownSeconds")
        let restored = RecorderPreferences(defaults: defaults)
        precondition(restored.framesPerSecond == 30 && restored.countdownSeconds == 3)
        print("PASS: Preferences defaults, restart persistence, and supported options")
    }
}
