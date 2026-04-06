import SwiftUI

struct AnalysisView: View {
    @EnvironmentObject private var portfolioVM: PortfolioViewModel
    @StateObject private var vm = AnalysisViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                header
                if vm.isLoading && vm.analysis == nil {
                    LoadingView(message: "Analysing portfolio...")
                        .frame(height: 300)
                } else if let analysis = vm.analysis {
                    sectorExposureCard(analysis.sectorExposure)
                    geoAndVolatilityRow(
                        geo: analysis.geographicBreakdown,
                        volatility: analysis.volatility
                    )
                    marketDynamicsSection(analysis.marketDynamics)
                    suggestionsSection(analysis.suggestions)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .refreshable {
            if let id = portfolioVM.selectedPortfolioID {
                await vm.refresh(portfolioID: id)
            }
        }
        .task {
            if let id = portfolioVM.selectedPortfolioID {
                await vm.load(portfolioID: id)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Portfolio Health")
                .trackedLabel()
                .foregroundStyle(Color.primary.opacity(0.8))
            Text("Analysis")
                .font(.displaySm)
                .foregroundStyle(Color.onSurface)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
    }

    // MARK: - Sector Exposure Card (glass treatment — hero card)

    private func sectorExposureCard(_ sectors: [SectorExposure]) -> some View {
        GlassCard(cornerRadius: 24, showGlow: true, padding: 24) {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sector Exposure")
                            .trackedLabel()
                            .foregroundStyle(Color.secondaryText)
                        Text("Concentration Index")
                            .font(.headlineSm)
                            .foregroundStyle(Color.onSurface)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.primary.opacity(0.10))
                            .frame(width: 44, height: 44)
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(Color.primary)
                    }
                }

                VStack(spacing: 20) {
                    ForEach(sectors) { sector in
                        SectorBar(sector: sector, isPrimary: sectors.first?.id == sector.id)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Geographic + Volatility side-by-side row

    private func geoAndVolatilityRow(
        geo: [GeographicExposure],
        volatility: VolatilityScore
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            geographicCard(geo)
            volatilityCard(volatility)
        }
    }

    private func geographicCard(_ geo: [GeographicExposure]) -> some View {
        SurfaceCard(cornerRadius: 20, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Geographic")
                    .trackedLabel()
                    .foregroundStyle(Color.secondaryText)

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(geo) { item in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(dotColor(for: item.region))
                                .frame(width: 8, height: 8)
                            Text("\(item.region) \(String(format: "%.0f", item.percentage))%")
                                .font(.labelMd.weight(.medium))
                                .foregroundStyle(Color.onSurface)
                                .textCase(.uppercase)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func volatilityCard(_ v: VolatilityScore) -> some View {
        SurfaceCard(cornerRadius: 20, padding: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Volatility")
                    .trackedLabel()
                    .foregroundStyle(Color.secondaryText)
                Spacer()
                Text(v.label)
                    .font(.displaySm)
                    .foregroundStyle(volatilityColor(v.label))
                Text(v.description)
                    .font(.labelMd)
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        }
    }

    // MARK: - Market Dynamics

    private func marketDynamicsSection(_ dynamics: [MarketDynamic]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Market Dynamics")
                    .trackedLabel()
                    .foregroundStyle(Color.secondaryText)
                Spacer()
                Text("1D Change")
                    .trackedLabel()
                    .foregroundStyle(Color.primary)
            }

            VStack(spacing: 0) {
                ForEach(Array(dynamics.enumerated()), id: \.element.id) { index, item in
                    MarketDynamicRow(item: item)
                    if index < dynamics.count - 1 {
                        Divider()
                            .opacity(0.05)
                            .padding(.leading, 76)
                    }
                }
            }
            .background(Color.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.outlineVariant.opacity(0.10), lineWidth: 1)
            }
        }
    }

    // MARK: - Optimization Suggestions

    private func suggestionsSection(_ suggestions: [OptimizationSuggestion]) -> some View {
        VStack(spacing: 12) {
            ForEach(suggestions) { suggestion in
                SuggestionCard(suggestion: suggestion)
            }
        }
    }

    // MARK: - Helpers

    private func dotColor(for region: String) -> Color {
        switch region {
        case "USA":    return Color.primary
        case "EU":     return Color.outline
        case "Asia":   return Color.outlineVariant
        default:       return Color.secondary
        }
    }

    private func volatilityColor(_ label: String) -> Color {
        switch label {
        case "Low":      return Color.primary
        case "Medium":   return Color.secondary
        case "High":     return Color.tertiary
        default:         return Color.appError
        }
    }
}

// MARK: - Sector Progress Bar

private struct SectorBar: View {
    let sector: SectorExposure
    let isPrimary: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(sector.name)
                    .font(.bodyMd.weight(.medium))
                    .foregroundStyle(Color.onSurface)
                Spacer()
                Text(String(format: "%.1f%%", sector.percentage))
                    .font(.labelLg.weight(.bold))
                    .foregroundStyle(isPrimary ? Color.primary : Color.secondaryText)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.surfaceContainerHighest)
                        .frame(height: 6)

                    // Fill
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(isPrimary
                              ? Color.primary
                              : Color.outline.opacity(isPrimary ? 1.0 : 0.6))
                        .frame(width: geo.size.width * (sector.percentage / 100), height: 6)
                        .shadow(
                            color: isPrimary ? Color.primary.opacity(0.4) : .clear,
                            radius: 6, x: 0, y: 0
                        )
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Market Dynamic Row

private struct MarketDynamicRow: View {
    let item: MarketDynamic

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.surfaceContainerHighest)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Circle().strokeBorder(Color.outlineVariant.opacity(0.10))
                    }
                Image(systemName: item.categoryIcon)
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(Color.onSurfaceVariant)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.category)
                    .font(.titleMd)
                    .foregroundStyle(Color.onSurface)
                Text(item.symbol.uppercased())
                    .trackedLabel()
                    .foregroundStyle(Color.secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "%@%.1f%%",
                            item.isPositive ? "+" : "",
                            item.changePercent))
                    .font(.titleMd)
                    .foregroundStyle(item.isPositive ? Color.gainGreen : Color.lossRed)
                Text(item.period)
                    .trackedLabel()
                    .foregroundStyle(Color.secondaryText)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }
}

// MARK: - Optimization Suggestion Card

private struct SuggestionCard: View {
    let suggestion: OptimizationSuggestion

    private var accentColor: Color {
        switch suggestion.severity {
        case "warning":  return Color.tertiary
        case "critical": return Color.appError
        default:         return Color.primary
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: suggestion.icon)
                .font(.system(size: 18))
                .foregroundStyle(accentColor)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(suggestion.title)
                    .font(.titleMd)
                    .foregroundStyle(Color.onSurface)
                Text(suggestion.message)
                    .font(.bodyMd)
                    .foregroundStyle(Color.secondaryText)
                    .lineSpacing(3)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accentColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(accentColor.opacity(0.20), lineWidth: 1)
        }
    }
}
