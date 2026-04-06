import Vapor
import Fluent

struct HoldingController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let holdings = routes.grouped("portfolios", ":portfolioID", "holdings")
        holdings.get(use: index)
        holdings.post(use: create)
        holdings.group(":holdingID") { holding in
            holding.get(use: show)
            holding.delete(use: delete)
        }
    }

    // GET /api/v1/portfolios/:portfolioID/holdings
    func index(req: Request) async throws -> [HoldingResponse] {
        let portfolioID = try getPortfolioID(req)
        let holdings = try await Holding.query(on: req.db)
            .filter(\.$portfolio.$id == portfolioID)
            .all()
        return holdings.map { $0.toResponse() }
    }

    // POST /api/v1/portfolios/:portfolioID/holdings
    func create(req: Request) async throws -> HoldingResponse {
        let portfolioID = try getPortfolioID(req)
        guard try await Portfolio.find(portfolioID, on: req.db) != nil else {
            throw Abort(.notFound, reason: "Portfolio not found")
        }
        let body = try req.content.decode(CreateHoldingRequest.self)

        // Prevent duplicate symbol in same portfolio
        let existing = try await Holding.query(on: req.db)
            .filter(\.$portfolio.$id == portfolioID)
            .filter(\.$symbol == body.symbol.uppercased())
            .first()
        if let existing {
            return existing.toResponse()
        }

        let holding = Holding(
            portfolioID: portfolioID,
            symbol: body.symbol.uppercased(),
            assetClass: body.assetClass,
            dataSource: body.dataSource,
            quantity: 0,
            avgCostBasis: 0
        )
        try await holding.save(on: req.db)
        return holding.toResponse()
    }

    // GET /api/v1/portfolios/:portfolioID/holdings/:holdingID
    func show(req: Request) async throws -> HoldingResponse {
        let holding = try await findHolding(req)
        return holding.toResponse()
    }

    // DELETE /api/v1/portfolios/:portfolioID/holdings/:holdingID
    func delete(req: Request) async throws -> HTTPStatus {
        let holding = try await findHolding(req)
        try await holding.delete(on: req.db)
        return .noContent
    }

    private func getPortfolioID(_ req: Request) throws -> UUID {
        guard let id = req.parameters.get("portfolioID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid portfolio ID")
        }
        return id
    }

    private func findHolding(_ req: Request) async throws -> Holding {
        guard let id = req.parameters.get("holdingID", as: UUID.self),
              let holding = try await Holding.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        return holding
    }
}

extension Holding {
    func toResponse() -> HoldingResponse {
        HoldingResponse(
            id: id?.uuidString ?? "",
            symbol: symbol,
            assetClass: assetClass,
            dataSource: dataSource,
            quantity: quantity,
            avgCostBasis: avgCostBasis
        )
    }
}
