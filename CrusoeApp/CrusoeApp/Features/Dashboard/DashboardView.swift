import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var vm: PortfolioViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                header
                if vm.isLoading && vm.summary == nil {
                    LoadingView(message: "Loading portfolio...")
                        .frame(height: 200)
                } else if let summary = vm.summary {
                    totalValueHero(summary: summary)
                    holdingsSection(summary: summary)
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // space above tab bar
        }
        .scrollIndicators(.hidden)
        .refreshable { await vm.manualRefresh() }
    }

    // MARK: - Header (matches HTML: net worth label + balance + icon)

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Net Worth")
                    .trackedLabel()
                    .foregroundStyle(Color.secondaryText)
                Text(vm.totalValue.formatted(.currency(code: "USD")))
                    .font(.headlineLg)
                    .foregroundStyle(Color.primary)
            }
            Spacer()
            HStack(spacing: 12) {
                PulseNode()
                Button {
                    Task { await vm.manualRefresh() }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(Color.primary)
                }
                .disabled(vm.isLoading)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Hero value card (glass treatment)

    private func totalValueHero(summary: PortfolioSummary) -> some View {
        GlassCard(cornerRadius: 24, showGlow: true, padding: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Portfolio Value")
                    .trackedLabel()
                    .foregroundStyle(Color.secondaryText)

                Text(summary.totalValue.formatted(.currency(code: "USD")))
                    .font(.displayMd)
                    .foregroundStyle(Color.onSurface)

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Day Change")
                            .trackedLabel()
                            .foregroundStyle(Color.secondaryText)
                        PriceChangeLabel(
                            change: summary.totalDayChange,
                            percent: (summary.totalDayChange / max(summary.totalCostBasis, 1)) * 100,
                            style: .large
                        )
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Total P&L")
                            .trackedLabel()
                            .foregroundStyle(Color.secondaryText)
                        PriceChangeLabel(
                            change: summary.totalUnrealizedPnL,
                            percent: summary.totalUnrealizedPnLPercent,
                            style: .large
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Holdings list

    private func holdingsSection(summary: PortfolioSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Market Dynamics")
                    .trackedLabel()
                    .foregroundStyle(Color.secondaryText)
                Spacer()
                NavigationLink(destination: HoldingsView()) {
                    Text("View All")
                        .trackedLabel()
                        .foregroundStyle(Color.primary)
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(summary.holdings.enumerated()), id: \.element.id) { index, item in
                    HoldingRowView(item: item, isLast: index == summary.holdings.count - 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie")
                .font(.system(size: 56, weight: .ultraLight))
                .foregroundStyle(Color.primary.opacity(0.6))
            Text("No Portfolio Yet")
                .font(.headlineSm)
                .foregroundStyle(Color.primaryText)
            Text("Go to Holdings to add your first asset.")
                .font(.bodyMd)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

// MARK: - Holding row (matches HTML "Market Dynamics" list style)

private struct HoldingRowView: View {
    let item: HoldingSummary
    let isLast: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Icon node
            ZStack {
                Circle()
                    .fill(Color.surfaceContainerHighest)
                    .frame(width: 44, height: 44)
                Image(systemName: item.holding.assetClass.icon)
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(Color.onSurfaceVariant)
            }

            // Name + subtitle
            VStack(alignment: .leading, spacing: 3) {
                Text(item.symbol)
                    .font(.titleMd)
                    .foregroundStyle(Color.onSurface)
                Text(item.holding.assetClass.displayName.uppercased())
                    .trackedLabel()
                    .foregroundStyle(Color.secondaryText)
            }

            Spacer()

            // Value + change
            VStack(alignment: .trailing, spacing: 3) {
                Text(item.marketValue.formatted(.currency(code: "USD")))
                    .font(.titleMd)
                    .foregroundStyle(Color.onSurface)
                PriceChangeLabel(
                    change: item.dayChange,
                    percent: item.dayChangePercent,
                    style: .small
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(Color.surfaceContainerLow)
        .overlay(alignment: .bottom) {
            if !isLast {
                Divider()
                    .opacity(0.05)
                    .padding(.leading, 76)
            }
        }
    }
}
