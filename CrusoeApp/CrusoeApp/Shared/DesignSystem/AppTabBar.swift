import SwiftUI

// MARK: - Tab Definition

enum AppTab: CaseIterable {
    case holdings, analysis, overview

    var label: String {
        switch self {
        case .holdings: return "Holdings"
        case .analysis: return "Analysis"
        case .overview: return "Overview"
        }
    }

    var icon: String {
        switch self {
        case .holdings: return "list.bullet.rectangle.portrait"
        case .analysis: return "chart.pie.fill"
        case .overview: return "square.grid.2x2.fill"
        }
    }
}

// MARK: - Custom Tab Bar

struct AppTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 28) // safe area breathing room
        .background {
            Rectangle()
                .fill(Color.surfaceContainerLow.opacity(0.9))
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) {
                    // Ghost top border
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(Color.outlineVariant.opacity(0.15))
                }
        }
        .clipShape(
            RoundedCorner(radius: 24, corners: [.topLeft, .topRight])
        )
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .symbolEffect(.bounce, value: isSelected)

                Text(tab.label)
                    .trackedLabel(spacing: 0.12)
                    .font(.labelCaps)
            }
            .foregroundStyle(isSelected ? Color.primary : Color.surfaceContainerHighest)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    // Active pill indicator
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.primary.opacity(0.10))
                        .padding(.horizontal, 8)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Root container wiring tabs to content

struct RootView: View {
    @State private var selectedTab: AppTab = .overview
    @EnvironmentObject private var portfolioVM: PortfolioViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            // Page content
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating tab bar
            AppTabBar(selectedTab: $selectedTab)
        }
        .appBackground()
        .preferredColorScheme(.dark)
        .task {
            await portfolioVM.loadInitialData()
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:
            DashboardView()
        case .holdings:
            HoldingsView()
        case .analysis:
            AnalysisView()
        }
    }
}

// MARK: - Helper: rounded specific corners

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
