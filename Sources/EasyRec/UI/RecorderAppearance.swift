import AppKit
import SwiftUI

// The explicit alias avoids an unavailable State macro plugin in standalone CLT.
typealias ViewState<Value> = SwiftUI.State<Value>

enum RecorderAppearance {
    static let toolbarSize = NSSize(width: 440, height: 82)
    static let cornerRadius: CGFloat = 16
    static let recordColor = Color(red: 0.94, green: 0.27, blue: 0.29)
    static let selectionColor = Color(red: 0.12, green: 0.4, blue: 0.83)

    static var toolbarShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }
}

struct RecorderBackground: View {
    var body: some View {
        if #available(macOS 26.0, *) {
            Color.white.opacity(0.96)
                .glassEffect(.clear, in: RecorderAppearance.toolbarShape)
        } else {
            LegacyGlassBackground()
                .overlay(Color.white.opacity(0.96))
                .clipShape(RecorderAppearance.toolbarShape)
                .overlay {
                    RecorderAppearance.toolbarShape
                        .strokeBorder(.white.opacity(0.7), lineWidth: 0.5)
                }
        }
    }
}

private struct LegacyGlassBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}
