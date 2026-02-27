import SwiftUI

extension Color {
    // MARK: - Backgrounds
    static let pledgeBg = Color("pledgeBg", bundle: nil)
    static let pledgeBgSecondary = Color("pledgeBgSecondary", bundle: nil)
    
    // MARK: - Primary
    static let pledgeBlack = Color("pledgeBlack", bundle: nil)
    static let pledgeWhite = Color("pledgeWhite", bundle: nil)
    
    // MARK: - Accents
    static let pledgeBlue = Color(hex: "0EA5E9")
    static let pledgeViolet = Color(hex: "7C3AED")
    static let pledgeGreen = Color(hex: "22C55E")
    static let pledgeRed = Color(hex: "EF4444")
    static let pledgeOrange = Color(hex: "F97316")
    
    // MARK: - Neutrals
    static let pledgeGray = Color(hex: "6B7280")
    static let pledgeGrayLight = Color(hex: "E5E7EB")
    static let pledgeGrayUltra = Color(hex: "F3F4F6")
    
    // MARK: - Adaptive
    static let pledgeBgAdaptive = Color(light: .white, dark: Color(hex: "0A0A0F"))
    static let pledgeBgSecondaryAdaptive = Color(light: Color(hex: "F8F9FA"), dark: Color(hex: "111118"))
    static let pledgeBlackAdaptive = Color(light: .black, dark: .white)
    static let pledgeGrayUltraAdaptive = Color(light: Color(hex: "F3F4F6"), dark: Color(hex: "1F2937"))
    
    // MARK: - Hex Init
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark: return UIColor(dark)
            default: return UIColor(light)
            }
        })
    }
}
