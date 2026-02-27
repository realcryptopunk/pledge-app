import SwiftUI

struct NumberPadView: View {
    @Binding var value: String
    var maxDigits: Int = 6
    var allowDecimal: Bool = true

    private let keys: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "←"]
    ]

    var body: some View {
        VStack(spacing: 4) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            handleTap(key)
                        } label: {
                            Group {
                                if key == "←" {
                                    Image(systemName: "delete.left")
                                        .font(.system(size: 20, weight: .medium))
                                } else {
                                    Text(key)
                                        .font(.system(size: 24, weight: .regular, design: .rounded))
                                }
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(NumberPadKeyStyle())
                    }
                }
            }
        }
    }

    private func handleTap(_ key: String) {
        PPHaptic.light()

        switch key {
        case "←":
            if !value.isEmpty {
                value.removeLast()
            }
        case ".":
            if allowDecimal && !value.contains(".") {
                value += value.isEmpty ? "0." : "."
            }
        default:
            let digits = value.replacingOccurrences(of: ".", with: "")
            if digits.count < maxDigits {
                if let dotIndex = value.firstIndex(of: ".") {
                    let decimals = value[value.index(after: dotIndex)...]
                    if decimals.count >= 2 { return }
                }
                value += key
            }
        }
    }
}

// MARK: - Key Style

private struct NumberPadKeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(configuration.isPressed ? Color.primary.opacity(0.1) : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    @Previewable @State var value = "25"
    ZStack {
        WaterBackgroundView()
        VStack {
            Text("$\(value)")
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundColor(.primary)
            NumberPadView(value: $value)
        }
        .padding()
    }
    .environmentObject(AppState())
}
