import SwiftUI

// MARK: - Design Token Colors
// All values sourced from the "Submerged Monolith" design system.
// Named to match the HTML tokens exactly so any design handoff is a 1:1 lookup.

extension Color {

    // MARK: Primary (Neon green — the light source)
    static let primary                  = Color("primary")
    static let primaryFixed             = Color("primary-fixed")
    static let primaryFixedDim          = Color("primary-fixed-dim")
    static let primaryContainer         = Color("primary-container")
    static let onPrimary                = Color("on-primary")
    static let onPrimaryContainer       = Color("on-primary-container")
    static let onPrimaryFixed           = Color("on-primary-fixed")
    static let onPrimaryFixedVariant    = Color("on-primary-fixed-variant")

    // MARK: Secondary
    static let secondary                = Color("secondary")
    static let secondaryFixed           = Color("secondary-fixed")
    static let secondaryFixedDim        = Color("secondary-fixed-dim")
    static let secondaryContainer       = Color("secondary-container")
    static let onSecondary              = Color("on-secondary")
    static let onSecondaryContainer     = Color("on-secondary-container")

    // MARK: Tertiary (warm coral — used for loss indicators)
    static let tertiary                 = Color("tertiary")
    static let tertiaryContainer        = Color("tertiary-container")
    static let onTertiary               = Color("on-tertiary")
    static let onTertiaryContainer      = Color("on-tertiary-container")

    // MARK: Error
    static let appError                 = Color("error")
    static let errorContainer           = Color("error-container")
    static let onError                  = Color("on-error")
    static let onErrorContainer         = Color("on-error-container")

    // MARK: Surface hierarchy (depth via tonal layering)
    static let surface                  = Color("surface")
    static let surfaceDim               = Color("surface-dim")
    static let surfaceBright            = Color("surface-bright")
    static let surfaceVariant           = Color("surface-variant")
    static let surfaceTint              = Color("surface-tint")
    static let surfaceContainerLowest   = Color("surface-container-lowest")
    static let surfaceContainerLow      = Color("surface-container-low")
    static let surfaceContainer         = Color("surface-container")
    static let surfaceContainerHigh     = Color("surface-container-high")
    static let surfaceContainerHighest  = Color("surface-container-highest")

    // MARK: On-Surface (text/icon colors)
    static let onSurface                = Color("on-surface")
    static let onSurfaceVariant         = Color("on-surface-variant")
    static let onBackground             = Color("on-background")
    static let background               = Color("background")

    // MARK: Outline (ghost borders)
    static let outline                  = Color("outline")
    static let outlineVariant           = Color("outline-variant")

    // MARK: Inverse
    static let inversePrimary           = Color("inverse-primary")
    static let inverseSurface           = Color("inverse-surface")
    static let inverseOnSurface         = Color("inverse-on-surface")
}

// MARK: - Semantic aliases
// Use these in UI code so intent is clear, not the raw token name.

extension Color {
    static let appBackground        = Color.surface
    static let cardBackground       = Color.surfaceContainerLow
    static let cardBackgroundRaised = Color.surfaceContainerHigh
    static let primaryText          = Color.onSurface
    static let secondaryText        = Color.onSurfaceVariant
    static let accent               = Color.primary
    static let lossRed              = Color.appError
    static let gainGreen            = Color.primary
}
