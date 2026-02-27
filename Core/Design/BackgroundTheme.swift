import SwiftUI

// MARK: - Theme Colors

struct ThemeColors: Equatable {
    let deep: Color
    let mid: Color
    let light: Color
    let surface: Color
    let foam: Color
    let isLight: Bool
    /// Override for button gradient top (defaults to mid)
    let _buttonTop: Color?
    /// Override for button gradient bottom (defaults to deep)
    let _buttonBottom: Color?

    init(deep: Color, mid: Color, light: Color, surface: Color, foam: Color,
         isLight: Bool = false, buttonTop: Color? = nil, buttonBottom: Color? = nil) {
        self.deep = deep
        self.mid = mid
        self.light = light
        self.surface = surface
        self.foam = foam
        self.isLight = isLight
        self._buttonTop = buttonTop
        self._buttonBottom = buttonBottom
    }

    var buttonTop: Color { _buttonTop ?? mid }
    var buttonBottom: Color { _buttonBottom ?? deep }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [deep, mid, light.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Background Theme

enum BackgroundTheme: String, CaseIterable, Identifiable {
    case clean
    case aqua
    case amethyst
    case emerald
    case sunset
    case rose
    case midnight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .clean: "Clean"
        case .aqua: "Aqua"
        case .amethyst: "Amethyst"
        case .emerald: "Emerald"
        case .sunset: "Sunset"
        case .rose: "Rose"
        case .midnight: "Midnight"
        }
    }

    var icon: String {
        switch self {
        case .clean: "cloud.fill"
        case .aqua: "drop.fill"
        case .amethyst: "sparkles"
        case .emerald: "leaf.fill"
        case .sunset: "sun.max.fill"
        case .rose: "heart.fill"
        case .midnight: "moon.stars.fill"
        }
    }

    var isLight: Bool { self == .clean }

    var colors: ThemeColors {
        switch self {
        case .clean:
            ThemeColors(
                deep: Color(hex: "F0F0FF"),
                mid: Color(hex: "E8EEFF"),
                light: Color(hex: "818CF8"),
                surface: Color(hex: "6366F1"),
                foam: .white,
                isLight: true,
                buttonTop: Color(hex: "818CF8"),
                buttonBottom: Color(hex: "4F46E5")
            )
        case .aqua:
            ThemeColors(
                deep: Color(hex: "0C4A6E"),
                mid: Color(hex: "0369A1"),
                light: Color(hex: "38BDF8"),
                surface: Color(hex: "7DD3FC"),
                foam: Color(hex: "E0F2FE")
            )
        case .amethyst:
            ThemeColors(
                deep: Color(hex: "3B0764"),
                mid: Color(hex: "7C3AED"),
                light: Color(hex: "A78BFA"),
                surface: Color(hex: "C4B5FD"),
                foam: Color(hex: "EDE9FE")
            )
        case .emerald:
            ThemeColors(
                deep: Color(hex: "064E3B"),
                mid: Color(hex: "059669"),
                light: Color(hex: "34D399"),
                surface: Color(hex: "6EE7B7"),
                foam: Color(hex: "D1FAE5")
            )
        case .sunset:
            ThemeColors(
                deep: Color(hex: "7C2D12"),
                mid: Color(hex: "C2410C"),
                light: Color(hex: "FB923C"),
                surface: Color(hex: "FDBA74"),
                foam: Color(hex: "FFF7ED")
            )
        case .rose:
            ThemeColors(
                deep: Color(hex: "831843"),
                mid: Color(hex: "BE185D"),
                light: Color(hex: "F472B6"),
                surface: Color(hex: "F9A8D4"),
                foam: Color(hex: "FCE7F3")
            )
        case .midnight:
            ThemeColors(
                deep: Color(hex: "0F172A"),
                mid: Color(hex: "1E293B"),
                light: Color(hex: "475569"),
                surface: Color(hex: "94A3B8"),
                foam: Color(hex: "E2E8F0")
            )
        }
    }

    /// Caustic ellipse colors for this theme
    var causticColors: [Color] {
        switch self {
        case .clean:
            // Soft pastels for light background
            [Color(hex: "C7D2FE"), Color(hex: "FBCFE8"), Color(hex: "BAE6FD"),
             Color(hex: "DDD6FE"), Color(hex: "FDE68A"), Color(hex: "C7D2FE"),
             Color(hex: "FBCFE8"), Color(hex: "BAE6FD"), Color(hex: "DDD6FE"),
             Color(hex: "FDE68A"), Color(hex: "C7D2FE"), Color(hex: "FBCFE8"),
             Color(hex: "BAE6FD")]
        default:
            [.white, colors.surface, .white, colors.light, .white, colors.surface,
             .white, colors.light, .white, colors.surface, .white, colors.light, .white]
        }
    }
}

// MARK: - Environment Key

private struct ThemeColorsKey: EnvironmentKey {
    static let defaultValue = BackgroundTheme.aqua.colors
}

extension EnvironmentValues {
    var themeColors: ThemeColors {
        get { self[ThemeColorsKey.self] }
        set { self[ThemeColorsKey.self] = newValue }
    }
}
