import XCTVapor
@testable import CrusoeServer

final class CrusoeServerTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = Application(.testing)
        app.databases.use(.sqlite(.memory), as: .sqlite)
        app.migrations.add(CreatePortfolio())
        app.migrations.add(CreateHolding())
        app.migrations.add(CreateTransaction())
        try await app.autoMigrate()
        try routes(app)
    }

    override func tearDown() async throws {
        try await app.autoRevert()
        app.shutdown()
    }

    // MARK: - Portfolio

    func testCreateAndFetchPortfolio() async throws {
        try await app.test(.POST, "/api/v1/portfolios", beforeRequest: { req in
            try req.content.encode(["name": "Test Portfolio", "currency": "USD"])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let portfolio = try res.content.decode(PortfolioResponse.self)
            XCTAssertEqual(portfolio.name, "Test Portfolio")
            XCTAssertEqual(portfolio.currency, "USD")
        })

        try await app.test(.GET, "/api/v1/portfolios", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let portfolios = try res.content.decode([PortfolioResponse].self)
            XCTAssertEqual(portfolios.count, 1)
        })
    }

    // MARK: - Transaction & Cost Basis

    func testBuyTransactionUpdatesCostBasis() async throws {
        // Create portfolio + holding
        var portfolioID = ""
        try await app.test(.POST, "/api/v1/portfolios", beforeRequest: { req in
            try req.content.encode(["name": "P", "currency": "USD"])
        }, afterResponse: { res in
            portfolioID = try res.content.decode(PortfolioResponse.self).id
        })

        var holdingID = ""
        try await app.test(.POST, "/api/v1/portfolios/\(portfolioID)/holdings", beforeRequest: { req in
            try req.content.encode(["symbol": "BTC", "assetClass": "crypto", "dataSource": "hyperliquid"])
        }, afterResponse: { res in
            holdingID = try res.content.decode(HoldingResponse.self).id
        })

        // Buy 1 BTC at $60,000
        try await app.test(.POST, "/api/v1/holdings/\(holdingID)/transactions", beforeRequest: { req in
            try req.content.encode(["type": "buy", "quantity": 1.0, "price": 60000.0, "fees": 0.0])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        // Buy 1 BTC at $70,000 → avg cost should be $65,000
        try await app.test(.POST, "/api/v1/holdings/\(holdingID)/transactions", beforeRequest: { req in
            try req.content.encode(["type": "buy", "quantity": 1.0, "price": 70000.0, "fees": 0.0])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        try await app.test(.GET, "/api/v1/portfolios/\(portfolioID)/holdings", afterResponse: { res in
            let holdings = try res.content.decode([HoldingResponse].self)
            let btc = holdings.first { $0.symbol == "BTC" }
            XCTAssertEqual(btc?.quantity, 2.0)
            XCTAssertEqual(btc?.avgCostBasis, 65000.0)
        })
    }
}
