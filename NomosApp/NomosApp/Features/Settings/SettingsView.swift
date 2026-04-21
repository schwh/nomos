import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                header
                themesSection
                aboutSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Personalize")
                .trackedLabel()
                .foregroundStyle(theme.current.accent.opacity(0.85))
            Text("Settings")
                .font(.displaySm)
                .foregroundStyle(Color.onSurface)
        }
        .padding(.top, 16)
    }

    private var themesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Theme")
                    .font(.headlineSm)
                    .foregroundStyle(Color.onSurface)
                Spacer()
                Text(theme.current.name.uppercased())
                    .trackedLabel()
                    .foregroundStyle(theme.current.accent)
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 148), spacing: 12)],
                spacing: 12
            ) {
                ForEach(AppTheme.all) { t in
                    ThemeCard(appTheme: t, isSelected: t.id == theme.current.id) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            theme.select(t)
                        }
                    }
                }
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headlineSm)
                .foregroundStyle(Color.onSurface)

            SurfaceCard(cornerRadius: 18) {
                VStack(spacing: 12) {
                    infoRow(label: "Version", value: "1.0.0")
                    Divider().background(Color.outlineVariant.opacity(0.15))
                    infoRow(label: "Build", value: "Nomos · dev")
                }
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.bodyMd)
                .foregroundStyle(Color.secondaryText)
            Spacer()
            Text(value)
                .font(.bodyMd)
                .foregroundStyle(Color.onSurface)
        }
    }
}

// MARK: - Theme preview card

private struct ThemeCard: View {
    let appTheme: AppTheme
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                preview

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(appTheme.name)
                            .font(.titleMd)
                            .foregroundStyle(Color.onSurface)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(appTheme.accent)
                        }
                    }
                    Text(appTheme.subtitle)
                        .font(.labelLg)
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .background(Color.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        isSelected ? appTheme.accent.opacity(0.65)
                                   : Color.outlineVariant.opacity(0.12),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
            .shadow(
                color: isSelected ? appTheme.accent.opacity(0.25) : .clear,
                radius: 14
            )
        }
        .buttonStyle(.plain)
    }

    private var preview: some View {
        ZStack {
            // Gradient base
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            appTheme.accent.opacity(0.45),
                            appTheme.accent.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Glass highlight (liquid-glass style sheen)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.35)
                .mask {
                    LinearGradient(
                        colors: [Color.white, .clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                }

            // Mini dot grid sample
            MiniDotGrid(tint: appTheme.dotTint)
                .opacity(0.9)

            // Accent puck
            Circle()
                .fill(appTheme.accent)
                .frame(width: 30, height: 30)
                .shadow(color: appTheme.accent.opacity(0.55), radius: 10)
        }
        .frame(height: 90)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct MiniDotGrid: View {
    let tint: Color

    var body: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 10
            let cx = size.width / 2, cy = size.height / 2
            let maxD = sqrt(cx * cx + cy * cy)
            var y: CGFloat = 5
            while y < size.height {
                var x: CGFloat = 5
                while x < size.width {
                    let dx = x - cx, dy = y - cy
                    let t = min(1, sqrt(dx * dx + dy * dy) / maxD)
                    let r = max(0, 1.1 * (1 - pow(t, 1.3) * 0.9))
                    if r > 0.25 {
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: x - r / 2, y: y - r / 2, width: r, height: r)),
                            with: .color(tint.opacity(0.28 + (1 - t) * 0.25))
                        )
                    }
                    x += spacing
                }
                y += spacing
            }
        }
        .allowsHitTesting(false)
    }
}
