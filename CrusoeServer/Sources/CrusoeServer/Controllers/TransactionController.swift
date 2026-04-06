import Vapor
import Fluent

struct TransactionController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let txns = routes.grouped("holdings", ":holdingID", "transactions")
        txns.get(use: index)
        txns.post(use: create)
        txns.group(":transactionID") { txn in
            txn.get(use: show)
            txn.delete(use: delete)
        }
    }

    // GET /api/v1/holdings/:holdingID/transactions
    func index(req: Request) async throws -> [TransactionResponse] {
        let holdingID = try getHoldingID(req)
        let txns = try await Transaction.query(on: req.db)
            .filter(\.$holding.$id == holdingID)
            .sort(\.$executedAt, .descending)
            .all()
        return txns.map { $0.toResponse() }
    }

    // POST /api/v1/holdings/:holdingID/transactions
    func create(req: Request) async throws -> TransactionResponse {
        let holdingID = try getHoldingID(req)
        guard let holding = try await Holding.find(holdingID, on: req.db) else {
            throw Abort(.notFound, reason: "Holding not found")
        }
        let body = try req.content.decode(CreateTransactionRequest.self)

        guard body.type == "buy" || body.type == "sell" else {
            throw Abort(.badRequest, reason: "Transaction type must be 'buy' or 'sell'")
        }
        guard body.quantity > 0 else {
            throw Abort(.badRequest, reason: "Quantity must be positive")
        }
        guard body.price > 0 else {
            throw Abort(.badRequest, reason: "Price must be positive")
        }
        if body.type == "sell" && body.quantity > holding.quantity {
            throw Abort(.badRequest, reason: "Cannot sell more than current holding (\(holding.quantity))")
        }

        let txn = Transaction(
            holdingID: holdingID,
            type: body.type,
            quantity: body.quantity,
            price: body.price,
            fees: body.fees ?? 0,
            executedAt: body.executedAt ?? Date(),
            notes: body.notes ?? ""
        )
        try await txn.save(on: req.db)

        // Recalculate holding quantity and average cost basis
        try await PortfolioEngine.recalculateHolding(holding, on: req.db)

        return txn.toResponse()
    }

    // GET /api/v1/holdings/:holdingID/transactions/:transactionID
    func show(req: Request) async throws -> TransactionResponse {
        let txn = try await findTransaction(req)
        return txn.toResponse()
    }

    // DELETE /api/v1/holdings/:holdingID/transactions/:transactionID
    func delete(req: Request) async throws -> HTTPStatus {
        let txn = try await findTransaction(req)
        let holdingID = txn.$holding.id
        try await txn.delete(on: req.db)

        // Recalculate after deletion
        if let holding = try await Holding.find(holdingID, on: req.db) {
            try await PortfolioEngine.recalculateHolding(holding, on: req.db)
        }
        return .noContent
    }

    private func getHoldingID(_ req: Request) throws -> UUID {
        guard let id = req.parameters.get("holdingID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid holding ID")
        }
        return id
    }

    private func findTransaction(_ req: Request) async throws -> Transaction {
        guard let id = req.parameters.get("transactionID", as: UUID.self),
              let txn = try await Transaction.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        return txn
    }
}

extension Transaction {
    func toResponse() -> TransactionResponse {
        TransactionResponse(
            id: id?.uuidString ?? "",
            holdingID: $holding.id.uuidString,
            type: type,
            quantity: quantity,
            price: price,
            fees: fees,
            totalCost: totalCost,
            executedAt: executedAt,
            notes: notes
        )
    }
}
