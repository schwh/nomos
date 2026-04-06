import Vapor
import Fluent

struct PortfolioEngine {
    // Build a live summary for a single holding given its current market quote
    func holdingSummary(holding: Holding, quote: MarketQuote?) -> HoldingSummary {
        let currentPrice = quote?.price ?? 0
        let marketValue = currentPrice * holding.quantity
        let costBasis = holding.avgCostBasis * holding.quantity
        let unrealizedPnL = marketValue - costBasis
        let unrealizedPnLPercent = costBasis > 0 ? (unrealizedPnL / costBasis) * 100 : 0
        let prevClose = quote?.previousClose ?? currentPrice
        let dayChange = (currentPrice - prevClose) * holding.quantity
        let dayChangePercent = prevClose > 0 ? ((currentPrice - prevClose) / prevClose) * 100 : 0

        return HoldingSummary(
            holding: holding.toResponse(),
            quote: quote,
            marketValue: marketValue,
            unrealizedPnL: unrealizedPnL,
            unrealizedPnLPercent: unrealizedPnLPercent,
            dayChange: dayChange,
            dayChangePercent: dayChangePercent
        )
    }

    // Recalculate quantity and average cost basis from full transaction history
    // Uses weighted average cost method
    static func recalculateHolding(_ holding: Holding, on db: Database) async throws {
        let transactions = try await Transaction.query(on: db)
            .filter(\.$holding.$id == holding.id!)
            .sort(\.$executedAt, .ascending)
            .all()

        var quantity: Double = 0
        var totalCost: Double = 0

        for txn in transactions {
            if txn.type == "buy" {
                // Weighted average: fold new purchase into running total
                totalCost += (txn.quantity * txn.price) + txn.fees
                quantity += txn.quantity
            } else if txn.type == "sell" {
                // Reduce position — cost basis per unit stays the same
                let avgCost = quantity > 0 ? totalCost / quantity : 0
                totalCost -= avgCost * txn.quantity
                quantity -= txn.quantity
            }
        }

        holding.quantity = max(0, quantity)
        holding.avgCostBasis = quantity > 0 ? totalCost / quantity : 0
        try await holding.save(on: db)
    }
}
