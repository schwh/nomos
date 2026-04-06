import Vapor
import Fluent
import FluentSQLiteDriver

public func configure(_ app: Application) throws {
    // MARK: - Database
    app.databases.use(.sqlite(.file("nomos.db")), as: .sqlite)

    // MARK: - Migrations
    app.migrations.add(CreatePortfolio())
    app.migrations.add(CreateHolding())
    app.migrations.add(CreateTransaction())
    try app.autoMigrate().wait()

    // MARK: - Middleware
    app.middleware.use(CORSMiddleware(configuration: .init(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType]
    )))

    // MARK: - Routes
    try routes(app)
}
