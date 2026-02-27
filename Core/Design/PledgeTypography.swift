import SwiftUI

// MARK: - Typography View Modifiers

extension View {
    func pledgeXL(_ size: CGFloat = 96) -> some View {
        self.font(.system(size: size, weight: .black, design: .rounded))
    }
    
    func pledgeHero(_ size: CGFloat = 56) -> some View {
        self.font(.system(size: size, weight: .bold, design: .rounded))
    }
    
    func pledgeDisplay(_ size: CGFloat = 36) -> some View {
        self.font(.system(size: size, weight: .bold, design: .rounded))
    }
    
    func pledgeTitle() -> some View {
        self.font(.system(size: 20, weight: .bold, design: .default))
    }
    
    func pledgeHeadline() -> some View {
        self.font(.system(size: 17, weight: .semibold, design: .default))
    }
    
    func pledgeBody() -> some View {
        self.font(.system(size: 15, weight: .regular, design: .default))
    }
    
    func pledgeCallout() -> some View {
        self.font(.system(size: 14, weight: .medium, design: .default))
    }
    
    func pledgeCaption() -> some View {
        self.font(.system(size: 12, weight: .medium, design: .default))
    }
    
    func pledgeMono() -> some View {
        self.font(.system(size: 15, weight: .semibold, design: .monospaced))
    }
    
    func pledgeMonoSmall() -> some View {
        self.font(.system(size: 12, weight: .medium, design: .monospaced))
    }
}

// MARK: - Font Helpers

extension Font {
    static func pledgeRounded(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    
    static let pledgeHeadlineFont: Font = .system(size: 17, weight: .semibold)
    static let pledgeBodyFont: Font = .system(size: 15, weight: .regular)
    static let pledgeCaptionFont: Font = .system(size: 12, weight: .medium)
    static let pledgeMonoFont: Font = .system(size: 15, weight: .semibold, design: .monospaced)
}
