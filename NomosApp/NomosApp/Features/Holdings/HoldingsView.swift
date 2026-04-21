import SwiftUI

struct HoldingsView: View {
    @EnvironmentObject private var vm: PortfolioViewModel
    @EnvironmentObject private var theme: ThemeManager

    @State private var showAddHolding = false
    @State private var detailItem: HoldingSummary?

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    sectionHeader
                    holdingsList
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .overlay {
                if vm.currentHoldings.isEmpty && !vm.isLoading {
                    emptyState
                }
            }

            // Floating add-holding card — expands from the + button.
            if showAddHolding {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .onTapGesture { closeSheet() }
                    .transition(.opacity)

                AddHoldingCard(
                    onCancel: { closeSheet() },
                    onSubmitted: { closeSheet() }
                )
                .padding(.horizontal, 20)
                .padding(.top, 100)
                .frame(maxHeight: .infinity, alignment: .top)
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.12, anchor: .topTrailing)
                            .combined(with: .opacity),
                        removal: .scale(scale: 0.12, anchor: .topTrailing)
                            .combined(with: .opacity)
                    )
                )
            }
        }
        .sheet(item: $detailItem) { item in
            NavigationStack {
                HoldingDetailView(item: item)
            }
            .presentationBackground(.regularMaterial)
        }
    }

    // MARK: - Section header

    private var sectionHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Portfolio Health")
                    .trackedLabel()
                    .foregroundStyle(theme.current.accent.opacity(0.8))
                Text("Holdings")
                    .font(.displaySm)
                    .foregroundStyle(Color.onSurface)
            }
            Spacer()
            Button {
                openSheet()
            } label: {
                ZStack {
                    Circle()
                        .fill(theme.current.accent.opacity(0.14))
                        .frame(width: 40, height: 40)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.current.accent)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 16)
        .padding(.bottom, 24)
    }

    // MARK: - Holdings list

    private var holdingsList: some View {
        VStack(spacing: 12) {
            ForEach(vm.currentHoldings) { item in
                Button {
                    detailItem = item
                } label: {
                    HoldingCard(item: item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.system(size: 52, weight: .ultraLight))
                .foregroundStyle(theme.current.accent.opacity(0.5))
            Text("No Holdings")
                .font(.headlineSm)
                .foregroundStyle(Color.onSurface)
            Text("Tap + to add your first asset.")
                .font(.bodyMd)
                .foregroundStyle(Color.secondaryText)
        }
    }

    // MARK: - Sheet transitions

    private func openSheet() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
            showAddHolding = true
        }
    }

    private func closeSheet() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            showAddHolding = false
        }
    }
}

// MARK: - Individual holding card

private struct HoldingCard: View {
    let item: HoldingSummary

    var body: some View {
        SurfaceCard(cornerRadius: 16, padding: 0) {
            HStack(spacing: 16) {
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
