import SwiftUI

// MARK: - Rolling Counter View

struct RollingCounterView: View {
    let value: Double
    var decimalPlaces: Int = 2
    var mainSize: CGFloat = 48
    var decimalSize: CGFloat = 28
    var trailingSize: CGFloat = 20

    private var dollars: Int { Int(value) }

    /// Break dollar amount into individual characters for per-digit rolling
    private var dollarCharacters: [Character] {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        let str = formatter.string(from: NSNumber(value: dollars)) ?? "\(dollars)"
        return Array(str)
    }

    private var decimalDigits: [Int] {
        let fraction = value - Double(dollars)
        let scaled = Int(fraction * pow(10.0, Double(decimalPlaces)))
        let str = String(format: "%0\(decimalPlaces)d", max(0, scaled))
        return str.compactMap { $0.wholeNumberValue }
    }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            // Dollar sign
            Text("$")
                .font(.system(size: mainSize * 0.65, weight: .bold, design: .rounded))
                .foregroundColor(.secondary.opacity(0.5))

            // Dollar amount — each digit rolls independently
            ForEach(Array(dollarCharacters.enumerated()), id: \.offset) { _, char in
                if let digit = char.wholeNumberValue {
                    SlotDigitView(digit: digit, size: mainSize, color: .primary)
                } else {
                    Text(String(char))
                        .font(.system(size: mainSize, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                }
            }

            // Decimal point
            Text(".")
                .font(.system(size: decimalSize, weight: .bold, design: .rounded))
                .foregroundColor(.primary.opacity(0.5))

            // First 2 decimal digits (cents) — medium size
            if decimalDigits.count >= 2 {
                SlotDigitView(digit: decimalDigits[0], size: decimalSize, color: .primary)
                SlotDigitView(digit: decimalDigits[1], size: decimalSize, color: .primary)
            }

            // Trailing digits — smaller/dimmer, these tick fast
            if decimalDigits.count > 2 {
                ForEach(2..<decimalDigits.count, id: \.self) { i in
                    SlotDigitView(
                        digit: decimalDigits[i],
                        size: trailingSize,
                        color: .secondary.opacity(i < 4 ? 0.8 : 0.5)
                    )
                }
            }
        }
    }
}

// MARK: - Slot Machine Digit (vertical scroll)

private struct SlotDigitView: View {
    let digit: Int
    var size: CGFloat
    var color: Color

    private var cellHeight: CGFloat { size * 1.15 }

    private var offset: CGFloat {
        -CGFloat(digit) * cellHeight
    }

    var body: some View {
        // Hidden "8" provides correct layout sizing + baseline
        Text("8")
            .font(.system(size: size, weight: .black, design: .rounded))
            .foregroundColor(.clear)
            .frame(width: size * 0.62)
            .overlay(alignment: .top) {
                VStack(spacing: 0) {
                    ForEach(0..<10, id: \.self) { num in
                        Text("\(num)")
                            .font(.system(size: size, weight: .black, design: .rounded))
                            .foregroundColor(color)
                            .frame(width: size * 0.62, height: cellHeight)
                    }
                }
                .offset(y: offset)
            }
            .clipped()
            .animation(.interpolatingSpring(stiffness: 200, damping: 20), value: digit)
    }
}
