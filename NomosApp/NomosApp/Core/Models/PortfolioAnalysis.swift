import Foundation

struct PortfolioAnalysis: Codable {
    let portfolioID: String
    let sectorExposure: [SectorExposure]
    let geographicBreakdown: [GeographicExposure]
    let volatility: VolatilityScore
    let marketDynamics: [MarketDynamic]
    let suggestions: [OptimizationSuggestion]
    let generatedAt: Date
}

struct SectorExposure: Codable, Identifiable {
    let name: String
    let percentage: Double
    let marketValue: Double
    let isOverweight: Bool
    var id: String { name }
}

struct GeographicExposure: Codable, Identifiable {
    let region: String
    let percentage: Double
    var id: String { region }
}

struct VolatilityScore: Codable {
    let label: String
    let beta: Double
    let description: String

    var color: String {
        switch label {
        case "Low":       return "gain"
        case "Medium":    return "neutral"
        case "High":      return "warning"
        default:          return "loss"
        }
    }
}

struct MarketDynamic: Codable, Identifiable {
    let symbol: String
    let category: String
    let categoryIcon: String
    let changePercent: Double
    let period: String
    var id: String { symbol }
    var isPositive: Bool { changePercent >= 0 }
}

struct OptimizationSuggestion: Codable, Identifiable {
    let title: String
    let message: String
    let severity: String  // "info", "warning", "critical"
    var id: String { title }

    var icon: String {
        switch severity {
        case "warning":  return "exclamationmark.triangle.fill"
        case "critical": return "xmark.octagon.fill"
        default:         return "lightbulb.fill"
        }
    }
}
