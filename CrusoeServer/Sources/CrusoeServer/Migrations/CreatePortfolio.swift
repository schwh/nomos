import Fluent

struct CreatePortfolio: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("portfolios")
            .id()
            .field("name", .string, .required)
            .field("currency", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("portfolios").delete()
    }
}
