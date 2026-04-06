import Fluent
import Vapor

final class Holding: Model, Content, @unchecked Sendable {
    static let schema = "holdings"

    @ID
    var id: UUID?

    @Parent(key: "portfolio_id")
    var portfolio: Portfolio

    // e.g. "AAPL", "BTC", "ETH", "XAUT" (gold perp on Hyperliquid)
    @Field(key: "symbol")
    var symbol: String

    // "stock", "crypto", "commodity", "forex"
    @Field(key: "asset_class")
    var assetClass: String

    // "hyperliquid", "finnhub", "yahoo"
    @Field(key: "data_source")
    var dataSource: String

    // Total shares/units held (net of buys and sells)
    @Field(key: "quantity")
    var quantity: Double

    // Weighted average cost per unit in portfolio currency
    @Field(key: "avg_cost_basis")
    var avgCostBasis: Double

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Children(for: \.$holding)
    var transactions: [Transaction]

    init() {}

    init(
        id: UUID? = nil,
        portfolioID: UUID,
        symbol: String,
        assetClass: String,
        dataSource: String,
        quantity: Double = 0,
        avgCostBasis: Double = 0
    ) {
        self.id = id
        self.$portfolio.id = portfolioID
        self.symbol = symbol
        self.assetClass = assetClass
        self.dataSource = dataSource
        self.quantity = quantity
        self.avgCostBasis = avgCostBasis
    }
}
