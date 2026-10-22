import AppKit
import Carbon

/// Carbon hot keys work while another app is active, without monitoring typed keys.
@MainActor
final class RecordingShortcuts: ObservableObject {
    static let shared = RecordingShortcuts()
    @Published private(set) var unavailable: [String] = []
    private var registrations: [EventHotKeyRef] = []
    private var handler: EventHandlerRef?

    func register() {
        guard handler == nil else { return }
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var key = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &key)
            guard status == noErr else { return status }
            let id = key.id
            Task { @MainActor in
                switch id {
                case 1: await RecorderModel.shared.toggleRecording()
                case 2: RecorderWindowController.shared.toggle()
                default: break
                }
            }
            return noErr
        }, 1, &event, nil, &handler)
        for (id, code, label) in [(UInt32(1), kVK_ANSI_R, "⌘⇧R"), (UInt32(2), kVK_ANSI_E, "⌘⇧E")] {
            var reference: EventHotKeyRef?
            let status = RegisterEventHotKey(UInt32(code), UInt32(cmdKey | shiftKey),
                EventHotKeyID(signature: 0x45524331, id: id), GetApplicationEventTarget(), 0, &reference)
            if status == noErr, let reference { registrations.append(reference) }
            else { unavailable.append(label) }
        }
    }
}
