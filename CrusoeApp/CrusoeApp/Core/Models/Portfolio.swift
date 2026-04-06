import Foundation

struct Portfolio: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let currency: String
    let createdAt: Date?

    // Computed from live summary — not persisted server-side
    var totalValue: Double = 0
    var totalUnrealizedPnL: Double = 0
    var totalUnrealizedPnLPercent: Double = 0
    var totalDayChange: Double = 0

    enum CodingKeys: String, CodingKey {
        case id, name, currency, createdAt
    }
}

struct PortfolioSummary: Codable {
    let portfolio: Portfolio
    let holdings: [HoldingSummary]
    let totalValue: Double
    let totalCostBasis: Double
    let totalUnrealizedPnL: Double
    let totalUnrealizedPnLPercent: Double
    let totalDayChange: Double
}
