import Foundation

struct RecorderPreferences: Equatable {
    var systemAudio = true
    var microphone = false
    var showsCursor = true
    var framesPerSecond = 30
    var countdownSeconds = 3
    var microphoneDeviceID = ""

    init(defaults: UserDefaults = .standard) {
        microphoneDeviceID = defaults.string(forKey: "microphoneDeviceID") ?? ""
        systemAudio = defaults.object(forKey: "systemAudio") as? Bool ?? true
        microphone = defaults.bool(forKey: "microphone")
        showsCursor = defaults.object(forKey: "showsCursor") as? Bool ?? true
        framesPerSecond = defaults.integer(forKey: "framesPerSecond") == 60 ? 60 : 30
        let delay = defaults.object(forKey: "countdownSeconds") as? Int ?? 3
        countdownSeconds = [0, 3, 5].contains(delay) ? delay : 3
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(microphoneDeviceID, forKey: "microphoneDeviceID")
        defaults.set(systemAudio, forKey: "systemAudio")
        defaults.set(microphone, forKey: "microphone")
        defaults.set(showsCursor, forKey: "showsCursor")
        defaults.set(framesPerSecond, forKey: "framesPerSecond")
        defaults.set(countdownSeconds, forKey: "countdownSeconds")
    }
}
