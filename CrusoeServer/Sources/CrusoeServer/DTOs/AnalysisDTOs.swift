import Vapor

// Full analysis response for a portfolio
struct PortfolioAnalysisResponse: Content {
    let portfolioID: String
    let sectorExposure: [SectorExposure]
    let geographicBreakdown: [GeographicExposure]
    let volatility: VolatilityScore
    let marketDynamics: [MarketDynamic]
    let suggestions: [OptimizationSuggestion]
    let generatedAt: Date
}

// MARK: - Sector Exposure

struct SectorExposure: Content {
    let name: String        // "Crypto", "Stock", "Commodity", "Forex"
    let percentage: Double  // 0–100
    let marketValue: Double
    let isOverweight: Bool  // > 50% threshold
}

// MARK: - Geographic Breakdown

struct GeographicExposure: Content {
    let region: String      // "USA", "EU", "ASIA", "Global"
    let percentage: Double
}

// MARK: - Volatility

struct VolatilityScore: Content {
    let label: String       // "Low", "Medium", "High"
    let beta: Double        // Weighted avg beta vs S&P 500
    let description: String // e.g. "Beta 0.84 against S&P 500"
}

// MARK: - Market Dynamics (top movers)

struct MarketDynamic: Content {
    let symbol: String
    let category: String    // "Growth Leaders", "Stability Anchor", "Speculative Hedge"
    let categoryIcon: String
    let changePercent: Double
    let period: String      // "1D"
}

// MARK: - Optimization Suggestions

struct OptimizationSuggestion: Content {
    let title: String
    let message: String
    let severity: String    // "info", "warning", "critical"
}
