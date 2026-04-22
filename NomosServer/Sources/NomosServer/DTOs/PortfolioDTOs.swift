import Vapor

// MARK: - Portfolio

struct CreatePortfolioRequest: Content {
    let name: String
    let currency: String?
}

struct PortfolioResponse: Content {
    let id: String
    let name: String
    let currency: String
    let createdAt: Date?
}

// MARK: - Holding

struct CreateHoldingRequest: Content {
    let symbol: String
    // "stock", "crypto", "commodity", "forex"
    let assetClass: String
    // "hyperliquid", "finnhub", "yahoo", "coingecko"
    let dataSource: String
}

// One-shot "add (x) shares @ (y) price" — creates the holding and its first
// transaction atomically. `quantity` and `price` are required; the rest are
// optional.
struct CreatePositionRequest: Content {
    let symbol: String
    let assetClass: String
    let dataSource: String?
    let quantity: Double
    let price: Double
    let fees: Double?
    let executedAt: Date?
    let notes: String?
}

// Direct override of a holding's shares/avg-cost, for quick corrections
// without going through the transaction ledger.
struct UpdateHoldingRequest: Content {
    let quantity: Double?
    let avgCostBasis: Double?
}

struct HoldingResponse: Content {
    let id: String
    let symbol: String
    let assetClass: String
    let dataSource: String
    let quantity: Double
    let avgCostBasis: Double
}

// MARK: - Transaction

struct CreateTransactionRequest: Content {
    let type: String        // "buy" or "sell"
    let quantity: Double
    let price: Double
    let fees: Double?
    let executedAt: Date?
    let notes: String?
}

struct TransactionResponse: Content {
    let id: String
    let holdingID: String
    let type: String
    let quantity: Double
    let price: Double
    let fees: Double
    let totalCost: Double
    let executedAt: Date
    let notes: String
}

// MARK: - Portfolio Summary (live P&L)

struct HoldingSummary: Content {
    let holding: HoldingResponse
    let quote: MarketQuote?
    let marketValue: Double
    let unrealizedPnL: Double
    let unrealizedPnLPercent: Double
    let dayChange: Double
    let dayChangePercent: Double
}

struct PortfolioSummary: Content {
    let portfolio: PortfolioResponse
    let holdings: [HoldingSummary]
    let totalValue: Double
    let totalCostBasis: Double
    let totalUnrealizedPnL: Double
    let totalUnrealizedPnLPercent: Double
    let totalDayChange: Double
}
