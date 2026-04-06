import Fluent

struct CreateTransaction: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("transactions")
            .id()
            .field("holding_id", .uuid, .required, .references("holdings", "id", onDelete: .cascade))
            .field("type", .string, .required)
            .field("quantity", .double, .required)
            .field("price", .double, .required)
            .field("fees", .double, .required)
            .field("executed_at", .datetime, .required)
            .field("created_at", .datetime)
            .field("notes", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("transactions").delete()
    }
}
