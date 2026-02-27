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
        VStack(spacing: 16) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(row, id: \.self) { key in
                        NumberPadKey(key: key) {
                            handleTap(key)
                        }
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
            // Enforce max digits (excluding decimal point)
            let digits = value.replacingOccurrences(of: ".", with: "")
            if digits.count < maxDigits {
                // Limit decimal places to 2
                if let dotIndex = value.firstIndex(of: ".") {
                    let decimals = value[value.index(after: dotIndex)...]
                    if decimals.count >= 2 { return }
                }
                value += key
            }
        }
    }
}

struct NumberPadKey: View {
    let key: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Group {
                if key == "←" {
                    Image(systemName: "delete.left")
                        .font(.system(size: 22, weight: .regular))
                } else {
                    Text(key)
                        .font(.system(size: 28, weight: .regular))
                }
            }
            .foregroundColor(.pledgeBlackAdaptive)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pledgeGrayUltraAdaptive.opacity(isPressed ? 1 : 0))
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.linear(duration: 0.05)) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.linear(duration: 0.15)) { isPressed = false }
                }
        )
    }
}

#Preview {
    @Previewable @State var value = "25"
    VStack {
        Text("$\(value)")
            .font(.system(size: 72, weight: .black, design: .rounded))
        NumberPadView(value: $value)
    }
    .padding()
}
