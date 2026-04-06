import Vapor
import Fluent

struct PortfolioController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let portfolios = routes.grouped("portfolios")
        portfolios.get(use: index)
        portfolios.post(use: create)
        portfolios.group(":portfolioID") { portfolio in
            portfolio.get(use: show)
            portfolio.delete(use: delete)
            portfolio.get("summary", use: summary)
        }
    }

    // GET /api/v1/portfolios
    func index(req: Request) async throws -> [PortfolioResponse] {
        let portfolios = try await Portfolio.query(on: req.db).all()
        return portfolios.map { $0.toResponse() }
    }

    // POST /api/v1/portfolios
    func create(req: Request) async throws -> PortfolioResponse {
        let body = try req.content.decode(CreatePortfolioRequest.self)
        let portfolio = Portfolio(name: body.name, currency: body.currency ?? "USD")
        try await portfolio.save(on: req.db)
        return portfolio.toResponse()
    }

    // GET /api/v1/portfolios/:id
    func show(req: Request) async throws -> PortfolioResponse {
        let portfolio = try await findPortfolio(req)
        return portfolio.toResponse()
    }

    // DELETE /api/v1/portfolios/:id
    func delete(req: Request) async throws -> HTTPStatus {
        let portfolio = try await findPortfolio(req)
        try await portfolio.delete(on: req.db)
        return .noContent
    }

    // GET /api/v1/portfolios/:id/summary  — live P&L snapshot
    func summary(req: Request) async throws -> PortfolioSummary {
        let portfolio = try await findPortfolio(req)
        let holdings = try await Holding.query(on: req.db)
            .filter(\.$portfolio.$id == portfolio.id!)
            .all()

        let marketService = MarketDataService(client: req.client)
        let symbols = holdings.map { (symbol: $0.symbol, source: $0.dataSource) }
        let quotes = try await marketService.quotes(for: symbols)

        let engine = PortfolioEngine()
        let holdingSummaries = holdings.map { holding in
            engine.holdingSummary(holding: holding, quote: quotes[holding.symbol])
        }

        let totalValue = holdingSummaries.reduce(0) { $0 + $1.marketValue }
        let totalCostBasis = holdings.reduce(0) { $0 + ($1.avgCostBasis * $1.quantity) }
        let totalPnL = totalValue - totalCostBasis
        let totalPnLPercent = totalCostBasis > 0 ? (totalPnL / totalCostBasis) * 100 : 0
        let totalDayChange = holdingSummaries.reduce(0) { $0 + $1.dayChange }

        return PortfolioSummary(
            portfolio: portfolio.toResponse(),
            holdings: holdingSummaries,
            totalValue: totalValue,
            totalCostBasis: totalCostBasis,
            totalUnrealizedPnL: totalPnL,
            totalUnrealizedPnLPercent: totalPnLPercent,
            totalDayChange: totalDayChange
        )
    }

    private func findPortfolio(_ req: Request) async throws -> Portfolio {
        guard let id = req.parameters.get("portfolioID", as: UUID.self),
              let portfolio = try await Portfolio.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        return portfolio
    }
}

extension Portfolio {
    func toResponse() -> PortfolioResponse {
        PortfolioResponse(
            id: id?.uuidString ?? "",
            name: name,
            currency: currency,
            createdAt: createdAt
        )
    }
}
