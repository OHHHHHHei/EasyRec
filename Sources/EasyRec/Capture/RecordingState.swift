import Foundation

enum CaptureTargetKind {
    case display, window, region
}

enum RecordingPhase {
    case idle, choosing, choosingDestination, choosingRegion, countdown, starting, recording,
        pausing, paused, finishing, stopFailed

    var isBusy: Bool {
        self == .countdown || self == .starting || self == .recording || self == .pausing
            || self == .paused || self == .finishing || self == .stopFailed
    }
    var title: String {
        switch self {
        case .idle: return "准备录制"
        case .choosing: return "选择录制内容"
        case .choosingDestination: return "选择保存位置"
        case .choosingRegion: return "框选录制区域"
        case .countdown: return "即将开始录制"
        case .starting: return "正在启动"
        case .recording: return "正在录制"
        case .pausing: return "正在暂停"
        case .paused: return "已暂停"
        case .finishing: return "正在保存"
        case .stopFailed: return "请重试停止"
        }
    }
}

enum CaptureError: LocalizedError {
    case invalidSize
    case microphoneUnavailable
    case microphoneDenied

    var errorDescription: String? {
        switch self {
        case .invalidSize: return "录制区域尺寸无效，请重新选择屏幕或窗口。"
        case .microphoneUnavailable: return "所选麦克风不可用，请在设置中重新选择。"
        case .microphoneDenied: return "麦克风权限未开启。请在系统设置中允许访问，或关闭麦克风录制。"
        }
    }
}
