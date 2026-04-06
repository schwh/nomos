import SwiftUI

// MARK: - Typography Scale
// Matches the "Editorial Edge" spec from the design system.
//
// Manrope → SF Pro Rounded  (geometric purity, wide tracking — near-identical)
// Inter   → SF Pro          (the default system font; Inter was modelled on it)
//
// This gives us the same visual character with Dynamic Type, zero bundle weight,
// and Apple's native hinting engine — a better outcome than a bundled TTF.

extension Font {

    // MARK: Display (hero numbers — wealth figures)
    static var displayLg: Font {
        .system(size: 48, weight: .heavy, design: .rounded)
    }
    static var displayMd: Font {
        .system(size: 36, weight: .bold, design: .rounded)
    }
    static var displaySm: Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }

    // MARK: Headline (section titles)
    static var headlineLg: Font {
        .system(size: 24, weight: .bold, design: .rounded)
    }
    static var headlineMd: Font {
        .system(size: 20, weight: .bold, design: .rounded)
    }
    static var headlineSm: Font {
        .system(size: 17, weight: .semibold, design: .rounded)
    }

    // MARK: Title (card headers, list titles)
    static var titleLg: Font {
        .system(size: 16, weight: .semibold, design: .default)
    }
    static var titleMd: Font {
        .system(size: 14, weight: .semibold, design: .default)
    }

    // MARK: Body (data values, descriptions)
    static var bodyLg: Font {
        .system(size: 16, weight: .regular, design: .default)
    }
    static var bodyMd: Font {
        .system(size: 14, weight: .regular, design: .default)
    }

    // MARK: Label (metadata, secondary info)
    static var labelLg: Font {
        .system(size: 12, weight: .medium, design: .default)
    }
    static var labelMd: Font {
        .system(size: 11, weight: .medium, design: .default)
    }
    // All-caps tracked label — "NET WORTH", "MTD", section headers
    static var labelCaps: Font {
        .system(size: 10, weight: .semibold, design: .default)
    }
}

// MARK: - Tracking (letter-spacing) modifiers
// SwiftUI doesn't have a direct `tracking` modifier on Font,
// so we wrap it in a ViewModifier for the design system's tracked labels.

struct TrackedLabel: ViewModifier {
    var spacing: CGFloat = 0.15  // em units → approximate pt value

    func body(content: Content) -> some View {
        content
            .font(.labelCaps)
            .kerning(spacing * 10)
            .textCase(.uppercase)
    }
}

extension View {
    /// Applies the design system's all-caps tracked label style (used for section headers, metadata tags).
    func trackedLabel(spacing: CGFloat = 0.15) -> some View {
        modifier(TrackedLabel(spacing: spacing))
    }
}
