import SwiftUI

// MARK: - Tab Definition

enum AppTab: CaseIterable {
    case holdings, analysis, overview, news, settings

    var label: String {
        switch self {
        case .holdings: return "Holdings"
        case .analysis: return "Analysis"
        case .overview: return "Overview"
        case .news:     return "Signals"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .holdings: return "list.bullet.rectangle.portrait"
        case .analysis: return "chart.pie.fill"
        case .overview: return "square.grid.2x2.fill"
        case .news:     return "bolt.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Floating Liquid-Glass Tab Bar

struct AppTabBar: View {
    @Binding var selectedTab: AppTab
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background {
            // Layered glass: tonal floor → material → specular highlight
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.surfaceContainerLow.opacity(0.55))
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.85)
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blendMode(.screen)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            theme.current.accent.opacity(0.20)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    @Namespace private var tabNS

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                selectedTab = tab
            }
        } label: {
            Image(systemName: tab.icon)
                .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                .animation(nil, value: isSelected)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(theme.current.accent.opacity(0.18))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(theme.current.accent.opacity(0.45), lineWidth: 1)
                            }
                            .shadow(color: theme.current.accent.opacity(0.35), radius: 10)
                            .matchedGeometryEffect(id: "tabPill", in: tabNS)
                    }
                }
                .foregroundStyle(
                    isSelected ? theme.current.accent : Color.onSurfaceVariant.opacity(0.75)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Root container wiring tabs to content

struct RootView: View {
    @State private var selectedTab: AppTab = .overview
    @EnvironmentObject private var portfolioVM: PortfolioViewModel
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        ZStack(alignment: .bottom) {
            // All tabs mounted simultaneously and swapped via opacity —
            // preserves state, avoids view-tree rebuilds, and removes the
            // stutter on tab change.
            ZStack {
                tabLayer(.overview) { DashboardView() }
                tabLayer(.holdings) { HoldingsView() }
                tabLayer(.analysis) { AnalysisView() }
                tabLayer(.news)     { NewsView() }
                tabLayer(.settings) { SettingsView() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeOut(duration: 0.18), value: selectedTab)

            AppTabBar(selectedTab: $selectedTab)
        }
        .appBackground()
        .tint(theme.current.accent)
        .preferredColorScheme(.dark)
        .task {
            await portfolioVM.loadInitialData()
        }
    }

    @ViewBuilder
    private func tabLayer<Content: View>(_ tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        let isActive = selectedTab == tab
        content()
            .opacity(isActive ? 1 : 0)
            .allowsHitTesting(isActive)
    }
}
