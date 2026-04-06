import SwiftUI

struct HoldingsView: View {
    @EnvironmentObject private var vm: PortfolioViewModel
    @State private var showAddHolding = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    sectionHeader
                    holdingsList
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddHolding) {
                AddHoldingView()
            }
            .overlay {
                if vm.currentHoldings.isEmpty && !vm.isLoading {
                    emptyState
                }
            }
        }
    }

    // MARK: - Section header

    private var sectionHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Portfolio Health")
                    .trackedLabel()
                    .foregroundStyle(Color.primary.opacity(0.8))
                Text("Holdings")
                    .font(.displaySm)
                    .foregroundStyle(Color.onSurface)
            }
            Spacer()
            Button {
                showAddHolding = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.10))
                        .frame(width: 40, height: 40)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.primary)
                }
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 24)
    }

    // MARK: - Holdings list (no dividers — "Invisible List" rule)

    private var holdingsList: some View {
        VStack(spacing: 12) {
            ForEach(vm.currentHoldings) { item in
                NavigationLink(destination: HoldingDetailView(item: item)) {
                    HoldingCard(item: item)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { await vm.deleteHolding(item.holding) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.system(size: 52, weight: .ultraLight))
                .foregroundStyle(Color.primary.opacity(0.5))
            Text("No Holdings")
                .font(.headlineSm)
                .foregroundStyle(Color.onSurface)
            Text("Tap + to add your first asset.")
                .font(.bodyMd)
                .foregroundStyle(Color.secondaryText)
        }
    }
}

// MARK: - Individual holding card

private struct HoldingCard: View {
    let item: HoldingSummary

    var body: some View {
        SurfaceCard(cornerRadius: 16, padding: 0) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.surfaceContainerHighest)
                        .frame(width: 48, height: 48)
                        .overlay {
                            Circle().strokeBorder(Color.outlineVariant.opacity(0.10))
                        }
                    Image(systemName: item.holding.assetClass.icon)
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(Color.onSurfaceVariant)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.symbol)
                        .font(.titleLg)
                        .foregroundStyle(Color.onSurface)
                    Text(item.holding.dataSource.displayName.uppercased())
                        .trackedLabel()
                        .foregroundStyle(Color.secondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(item.marketValue.formatted(.currency(code: "USD")))
                        .font(.titleLg)
                        .foregroundStyle(Color.onSurface)
                    PriceChangeLabel(
                        change: item.unrealizedPnL,
                        percent: item.unrealizedPnLPercent,
                        style: .small
                    )
                }
            }
            .padding(16)
        }
    }
}
