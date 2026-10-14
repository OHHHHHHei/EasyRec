import SwiftUI

struct ToolbarTile: View {
    let title: String
    let icon: String
    let selected: Bool
    let action: () -> Void
    @ViewState private var hovering = false

    init(_ title: String, icon: String, selected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.selected = selected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 16, weight: .medium))
                Text(title).font(.system(size: 10, weight: .medium))
            }
            .frame(width: 44, height: 42)
            .foregroundStyle(selected ? RecorderAppearance.selectionColor : .primary.opacity(0.8))
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        selected
                            ? Color.blue.opacity(0.1) : hovering ? .black.opacity(0.05) : .clear)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(selected ? "已开启或选中" : "未开启或选中")
        .onHover { hovering = $0 }
    }
}
