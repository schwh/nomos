import Vapor
import Fluent

struct HoldingController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let holdings = routes.grouped("portfolios", ":portfolioID", "holdings")
        holdings.get(use: index)
        holdings.post(use: create)
        holdings.group(":holdingID") { holding in
            holding.get(use: show)
            holding.patch(use: update)
            holding.delete(use: delete)
        }

        // Atomic "add shares @ price" — creates holding + first transaction.
        routes.grouped("portfolios", ":portfolioID", "positions")
            .post(use: createPosition)
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

    // PATCH /api/v1/portfolios/:portfolioID/holdings/:holdingID
    // Direct override of quantity / avg cost. Skips the transaction ledger —
    // useful for correcting bad data without rebuilding history.
    func update(req: Request) async throws -> HoldingResponse {
        let holding = try await findHolding(req)
        let body = try req.content.decode(UpdateHoldingRequest.self)
        if let qty = body.quantity {
            guard qty >= 0 else { throw Abort(.badRequest, reason: "Quantity must be >= 0") }
            holding.quantity = qty
        }
        if let cost = body.avgCostBasis {
            guard cost >= 0 else { throw Abort(.badRequest, reason: "Avg cost must be >= 0") }
            holding.avgCostBasis = cost
        }
        try await holding.save(on: req.db)
        return holding.toResponse()
    }

    // DELETE /api/v1/portfolios/:portfolioID/holdings/:holdingID
    func delete(req: Request) async throws -> HTTPStatus {
        let holding = try await findHolding(req)
        try await holding.delete(on: req.db)
        return .noContent
    }

    // POST /api/v1/portfolios/:portfolioID/positions
    // Creates holding (if new) and seeds it with a BUY transaction in one call.
    func createPosition(req: Request) async throws -> HoldingResponse {
        let portfolioID = try getPortfolioID(req)
        guard try await Portfolio.find(portfolioID, on: req.db) != nil else {
            throw Abort(.notFound, reason: "Portfolio not found")
        }
        let body = try req.content.decode(CreatePositionRequest.self)
        guard body.quantity > 0 else { throw Abort(.badRequest, reason: "Quantity must be positive") }
        guard body.price > 0 else { throw Abort(.badRequest, reason: "Price must be positive") }

        let symbol = body.symbol.uppercased()
        let source = body.dataSource ?? defaultSource(for: body.assetClass)

        // Reuse an existing holding for this symbol if one already exists —
        // this lets "add shares @ price" behave like averaging up/down.
        let holding: Holding
        if let existing = try await Holding.query(on: req.db)
            .filter(\.$portfolio.$id == portfolioID)
            .filter(\.$symbol == symbol)
            .first()
        {
            holding = existing
        } else {
            holding = Holding(
                portfolioID: portfolioID,
                symbol: symbol,
                assetClass: body.assetClass,
                dataSource: source,
                quantity: 0,
                avgCostBasis: 0
            )
            try await holding.save(on: req.db)
        }

        let txn = Transaction(
            holdingID: try holding.requireID(),
            type: "buy",
            quantity: body.quantity,
            price: body.price,
            fees: body.fees ?? 0,
            executedAt: body.executedAt ?? Date(),
            notes: body.notes ?? ""
        )
        try await txn.save(on: req.db)
        try await PortfolioEngine.recalculateHolding(holding, on: req.db)

        return holding.toResponse()
    }

    private func defaultSource(for assetClass: String) -> String {
        switch assetClass {
        case "crypto":    return "hyperliquid"
        case "stock":     return "yahoo"
        case "commodity": return "yahoo"
        case "forex":     return "yahoo"
        default:          return "yahoo"
        }
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
