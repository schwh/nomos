import Fluent

struct CreateHolding: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("holdings")
            .id()
            .field("portfolio_id", .uuid, .required, .references("portfolios", "id", onDelete: .cascade))
            .field("symbol", .string, .required)
            .field("asset_class", .string, .required)
            .field("data_source", .string, .required)
            .field("quantity", .double, .required)
            .field("avg_cost_basis", .double, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "portfolio_id", "symbol")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("holdings").delete()
    }
}
