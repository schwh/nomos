import Vapor
import Fluent

struct AnalysisEngine {

    // Known beta values per asset class (vs S&P 500 proxy)
    private static let classBeta: [String: Double] = [
        "crypto":    1.85,
        "stock":     1.00,
        "commodity": 0.65,
        "forex":     0.25,
    ]

    // Geographic classification by ticker prefix / known symbols
    private static let usSymbols: Set<String> = [
        "AAPL","MSFT","GOOGL","GOOG","AMZN","NVDA","TSLA","META","BRK",
        "JPM","V","MA","UNH","JNJ","XOM","CVX","HD","PG","KO","PEP",
        "SPY","QQQ","IWM","VTI","DIA","VOO","GLD","SLV","USO","GDX",
    ]
    private static let euSymbols: Set<String> = [
        "SAP","ASML","NESN","NOVN","ROG","LVMH","MC","TTE","AIR","SIE",
    ]
    private static let asiaSymbols: Set<String> = [
        "BABA","TCEHY","9988.HK","7203.T","005930.KS","TSM","BIDU","JD","PDD",
    ]
    // Crypto and perpetuals on Hyperliquid are global
    private static let cryptoSymbols: Set<String> = [
        "BTC","ETH","SOL","BNB","XRP","ADA","DOGE","AVAX","DOT","MATIC",
        "LINK","UNI","LTC","ATOM","XLM","APT","ARB","OP","INJ","TIA",
    ]

    // MARK: - Main analysis builder

    func buildAnalysis(
        portfolioID: String,
        holdings: [Holding],
        quotes: [String: MarketQuote]
    ) -> PortfolioAnalysisResponse {

        let totalValue = holdings.reduce(0.0) { sum, h in
            sum + (quotes[h.symbol]?.price ?? 0) * h.quantity
        }

        let sectorExposure = buildSectorExposure(holdings: holdings, quotes: quotes, totalValue: totalValue)
        let geographic = buildGeographic(holdings: holdings, quotes: quotes, totalValue: totalValue)
        let volatility = buildVolatility(holdings: holdings, quotes: quotes, totalValue: totalValue)
        let dynamics = buildMarketDynamics(holdings: holdings, quotes: quotes)
        let suggestions = buildSuggestions(sectorExposure: sectorExposure, volatility: volatility, holdings: holdings)

        return PortfolioAnalysisResponse(
            portfolioID: portfolioID,
            sectorExposure: sectorExposure,
            geographicBreakdown: geographic,
            volatility: volatility,
            marketDynamics: dynamics,
            suggestions: suggestions,
            generatedAt: Date()
        )
    }

    // MARK: - Sector Exposure

    private func buildSectorExposure(
        holdings: [Holding],
        quotes: [String: MarketQuote],
        totalValue: Double
    ) -> [SectorExposure] {
        var buckets: [String: Double] = [:]
        for h in holdings {
            let value = (quotes[h.symbol]?.price ?? 0) * h.quantity
            buckets[h.assetClass, default: 0] += value
        }
        return buckets
            .map { (cls, value) in
                let pct = totalValue > 0 ? (value / totalValue) * 100 : 0
                return SectorExposure(
                    name: displayName(for: cls),
                    percentage: pct,
                    marketValue: value,
                    isOverweight: pct > 50
                )
            }
            .sorted { $0.percentage > $1.percentage }
    }

    // MARK: - Geographic Breakdown

    private func buildGeographic(
        holdings: [Holding],
        quotes: [String: MarketQuote],
        totalValue: Double
    ) -> [GeographicExposure] {
        var geo: [String: Double] = ["USA": 0, "EU": 0, "Asia": 0, "Global": 0]

        for h in holdings {
            let value = (quotes[h.symbol]?.price ?? 0) * h.quantity
            let sym = h.symbol.uppercased()

            if h.assetClass == "crypto" || Self.cryptoSymbols.contains(sym) {
                geo["Global", default: 0] += value
            } else if Self.euSymbols.contains(sym) {
                geo["EU", default: 0] += value
            } else if Self.asiaSymbols.contains(sym) {
                geo["Asia", default: 0] += value
            } else {
                // Default to USA for unlisted stocks/ETFs on Finnhub/Yahoo
                geo["USA", default: 0] += value
            }
        }

        return geo
            .filter { $0.value > 0 }
            .map { region, value in
                GeographicExposure(
                    region: region,
                    percentage: totalValue > 0 ? (value / totalValue) * 100 : 0
                )
            }
            .sorted { $0.percentage > $1.percentage }
    }

    // MARK: - Volatility / Beta

    private func buildVolatility(
        holdings: [Holding],
        quotes: [String: MarketQuote],
        totalValue: Double
    ) -> VolatilityScore {
        guard totalValue > 0 else {
            return VolatilityScore(label: "N/A", beta: 0, description: "No holdings to evaluate")
        }

        var weightedBeta = 0.0
        for h in holdings {
            let value = (quotes[h.symbol]?.price ?? 0) * h.quantity
            let weight = value / totalValue
            let beta = Self.classBeta[h.assetClass] ?? 1.0
            weightedBeta += weight * beta
        }

        let label: String
        let description: String
        switch weightedBeta {
        case ..<0.5:
            label = "Low"
            description = String(format: "Beta %.2f against S&P 500", weightedBeta)
        case 0.5..<1.1:
            label = "Medium"
            description = String(format: "Beta %.2f against S&P 500", weightedBeta)
        case 1.1..<1.5:
            label = "High"
            description = String(format: "Beta %.2f — elevated market sensitivity", weightedBeta)
        default:
            label = "Very High"
            description = String(format: "Beta %.2f — significant crypto/speculative exposure", weightedBeta)
        }

        return VolatilityScore(label: label, beta: weightedBeta, description: description)
    }

    // MARK: - Market Dynamics (top 3 movers with context labels)

    private func buildMarketDynamics(
        holdings: [Holding],
        quotes: [String: MarketQuote]
    ) -> [MarketDynamic] {
        let sorted = holdings
            .compactMap { h -> (Holding, MarketQuote)? in
                guard let q = quotes[h.symbol] else { return nil }
                return (h, q)
            }
            .sorted { abs($0.1.changePercent) > abs($1.1.changePercent) }
            .prefix(3)

        let categoryLabels = ["Growth Leaders", "Stability Anchor", "Speculative Hedge"]
        let categoryIcons  = ["rocket.fill",    "shield.fill",      "bolt.fill"]

        return sorted.enumerated().map { index, pair in
            let (holding, quote) = pair
            return MarketDynamic(
                symbol: holding.symbol,
                category: categoryLabels[index],
                categoryIcon: categoryIcons[index],
                changePercent: quote.changePercent,
                period: "1D"
            )
        }
    }

    // MARK: - Optimization Suggestions

    private func buildSuggestions(
        sectorExposure: [SectorExposure],
        volatility: VolatilityScore,
        holdings: [Holding]
    ) -> [OptimizationSuggestion] {
        var suggestions: [OptimizationSuggestion] = []

        // 1. Overweight sector
        if let overweight = sectorExposure.first(where: { $0.isOverweight }) {
            let others = sectorExposure
                .filter { !$0.isOverweight && $0.name != overweight.name }
                .map { $0.name }
            let suggestTo = others.prefix(2).joined(separator: " or ")
            suggestions.append(OptimizationSuggestion(
                title: "Concentration Risk",
                message: "Your portfolio is currently \(String(format: "%.0f", overweight.percentage - 33))% overweight in \(overweight.name). Consider rebalancing into \(suggestTo.isEmpty ? "other asset classes" : suggestTo) to reduce risk.",
                severity: "warning"
            ))
        }

        // 2. High volatility from crypto
        if volatility.beta > 1.5 {
            suggestions.append(OptimizationSuggestion(
                title: "Volatility Alert",
                message: "Portfolio beta of \(String(format: "%.2f", volatility.beta)) indicates high sensitivity to market swings. Adding lower-beta assets (bonds, commodities) would stabilize returns.",
                severity: "warning"
            ))
        }

        // 3. Under-diversification
        if sectorExposure.count == 1 {
            suggestions.append(OptimizationSuggestion(
                title: "Single Asset Class",
                message: "All holdings are in \(sectorExposure[0].name). Diversifying across stocks, crypto, or commodities reduces correlation risk.",
                severity: "info"
            ))
        }

        // 4. All clear
        if suggestions.isEmpty {
            suggestions.append(OptimizationSuggestion(
                title: "Well Balanced",
                message: "Your portfolio is well diversified across \(sectorExposure.count) asset classes with a manageable beta of \(String(format: "%.2f", volatility.beta)).",
                severity: "info"
            ))
        }

        return suggestions
    }

    // MARK: - Helpers

    private func displayName(for assetClass: String) -> String {
        switch assetClass {
        case "stock":     return "Stocks"
        case "crypto":    return "Crypto"
        case "commodity": return "Commodities"
        case "forex":     return "Forex"
        default:          return assetClass.capitalized
        }
    }
}
