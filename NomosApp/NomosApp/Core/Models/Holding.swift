import Foundation

struct Holding: Identifiable, Codable, Hashable {
    let id: String
    let symbol: String
    let assetClass: AssetClass
    let dataSource: DataSource
    let quantity: Double
    let avgCostBasis: Double

    var costBasisTotal: Double { quantity * avgCostBasis }
}

struct HoldingSummary: Identifiable, Codable {
    let holding: Holding
    let quote: MarketQuote?
    let marketValue: Double
    let unrealizedPnL: Double
    let unrealizedPnLPercent: Double
    let dayChange: Double
    let dayChangePercent: Double

    var id: String { holding.id }
    var symbol: String { holding.symbol }
    var isPositive: Bool { unrealizedPnL >= 0 }
    var isDayPositive: Bool { dayChange >= 0 }
}

enum AssetClass: String, Codable, CaseIterable {
    case stock      = "stock"
    case crypto     = "crypto"
    case commodity  = "commodity"
    case forex      = "forex"

    var displayName: String {
        switch self {
        case .stock:     return "Stock"
        case .crypto:    return "Crypto"
        case .commodity: return "Commodity"
        case .forex:     return "Forex"
        }
    }

    var icon: String {
        switch self {
        case .stock:     return "chart.line.uptrend.xyaxis"
        case .crypto:    return "bitcoinsign.circle"
        case .commodity: return "cube.box"
        case .forex:     return "dollarsign.circle"
        }
    }
}

enum DataSource: String, Codable, CaseIterable {
    case hyperliquid = "hyperliquid"
    case finnhub     = "finnhub"
    case yahoo       = "yahoo"
    case coingecko   = "coingecko"

    var displayName: String {
        switch self {
        case .hyperliquid: return "Hyperliquid"
        case .finnhub:     return "Finnhub"
        case .yahoo:       return "Yahoo Finance"
        case .coingecko:   return "CoinGecko"
        }
    }

    /// Default source for a given asset class.
    /// Yahoo is preferred where it's keyless; Finnhub stays available as an
    /// opt-in upgrade for real-time US stock ticks (requires FINNHUB_API_KEY).
    static func defaultFor(_ assetClass: AssetClass) -> DataSource {
        switch assetClass {
        case .crypto:    return .hyperliquid
        case .stock:     return .yahoo
        case .commodity: return .yahoo
        case .forex:     return .yahoo
        }
    }
}
