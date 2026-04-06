import XCTest
@testable import NomosApp

final class NomosAppTests: XCTestCase {

    // MARK: - Model tests (no network required)

    func testTransactionTypeRawValues() {
        XCTAssertEqual(TransactionType.buy.rawValue, "buy")
        XCTAssertEqual(TransactionType.sell.rawValue, "sell")
    }

    func testDefaultDataSourceForAssetClass() {
        XCTAssertEqual(DataSource.defaultFor(.crypto), .hyperliquid)
        XCTAssertEqual(DataSource.defaultFor(.stock), .finnhub)
        XCTAssertEqual(DataSource.defaultFor(.commodity), .yahoo)
        XCTAssertEqual(DataSource.defaultFor(.forex), .yahoo)
    }

    func testMarketQuoteIsPositive() {
        let quote = MarketQuote(
            symbol: "BTC",
            price: 70000,
            previousClose: 68000,
            changePercent: 2.94,
            change: 2000,
            source: "hyperliquid",
            fetchedAt: Date()
        )
        XCTAssertTrue(quote.isPositive)
        XCTAssertTrue(quote.formattedChange.hasPrefix("+"))
    }

    func testHoldingCostBasisTotal() {
        let holding = Holding(
            id: "1",
            symbol: "AAPL",
            assetClass: .stock,
            dataSource: .finnhub,
            quantity: 10,
            avgCostBasis: 150
        )
        XCTAssertEqual(holding.costBasisTotal, 1500)
    }
}
