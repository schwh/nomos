import SwiftUI
import Combine

// One theme defines the app's accent color family and how the
// dotted canvas / background tint should read for that mood.
struct AppTheme: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let accent: Color
    let accentSoft: Color
    let dotTint: Color
    let backgroundTint: Color

    static let obsidian = AppTheme(
        id: "obsidian",
        name: "Obsidian",
        subtitle: "Neon green · the default",
        accent: Color(red: 0.49, green: 0.99, blue: 0.72),
        accentSoft: Color(red: 0.49, green: 0.99, blue: 0.72).opacity(0.25),
        dotTint: Color(red: 0.55, green: 1.00, blue: 0.78),
        backgroundTint: .clear
    )

    static let aurora = AppTheme(
        id: "aurora",
        name: "Aurora",
        subtitle: "Violet twilight",
        accent: Color(red: 0.64, green: 0.72, blue: 1.00),
        accentSoft: Color(red: 0.64, green: 0.72, blue: 1.00).opacity(0.25),
        dotTint: Color(red: 0.80, green: 0.65, blue: 1.00),
        backgroundTint: Color(red: 0.10, green: 0.08, blue: 0.22).opacity(0.55)
    )

    static let solar = AppTheme(
        id: "solar",
        name: "Solar",
        subtitle: "Amber trading floor",
        accent: Color(red: 1.00, green: 0.78, blue: 0.36),
        accentSoft: Color(red: 1.00, green: 0.78, blue: 0.36).opacity(0.25),
        dotTint: Color(red: 1.00, green: 0.67, blue: 0.32),
        backgroundTint: Color(red: 0.20, green: 0.12, blue: 0.05).opacity(0.55)
    )

    static let bloom = AppTheme(
        id: "bloom",
        name: "Bloom",
        subtitle: "Rose magnetic",
        accent: Color(red: 1.00, green: 0.56, blue: 0.76),
        accentSoft: Color(red: 1.00, green: 0.56, blue: 0.76).opacity(0.25),
        dotTint: Color(red: 1.00, green: 0.70, blue: 0.85),
        backgroundTint: Color(red: 0.20, green: 0.08, blue: 0.15).opacity(0.55)
    )

    static let mono = AppTheme(
        id: "mono",
        name: "Mono",
        subtitle: "Pure contrast",
        accent: Color(red: 0.94, green: 0.94, blue: 0.94),
        accentSoft: Color.white.opacity(0.22),
        dotTint: Color.white,
        backgroundTint: .black.opacity(0.35)
    )

    static let all: [AppTheme] = [.obsidian, .aurora, .solar, .bloom, .mono]
}

final class ThemeManager: ObservableObject {
    @Published private(set) var current: AppTheme
    private let storageKey = "selectedThemeID"

    init() {
        let id = UserDefaults.standard.string(forKey: storageKey) ?? AppTheme.obsidian.id
        self.current = AppTheme.all.first(where: { $0.id == id }) ?? .obsidian
    }

    func select(_ theme: AppTheme) {
        current = theme
        UserDefaults.standard.set(theme.id, forKey: storageKey)
    }
}
