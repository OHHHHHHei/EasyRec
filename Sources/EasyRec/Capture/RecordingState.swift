import Foundation

enum CaptureTargetKind {
    case display, window
}

enum RecordingPhase {
    case idle, choosing, choosingDestination, starting, recording, finishing, stopFailed

    var isBusy: Bool {
        self == .starting || self == .recording || self == .finishing || self == .stopFailed
    }
    var title: String {
        switch self {
        case .idle: return "准备录制"
        case .choosing: return "选择录制内容"
        case .choosingDestination: return "选择保存位置"
        case .starting: return "正在启动"
        case .recording: return "正在录制"
        case .finishing: return "正在保存"
        case .stopFailed: return "请重试停止"
        }
    }
}

enum CaptureError: LocalizedError {
    case invalidSize
    case microphoneDenied

    var errorDescription: String? {
        switch self {
        case .invalidSize: return "录制区域尺寸无效，请重新选择屏幕或窗口。"
        case .microphoneDenied: return "麦克风权限未开启。请在系统设置中允许访问，或关闭麦克风录制。"
        }
    }
}
