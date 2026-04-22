import Vapor
import Fluent
import FluentSQLiteDriver

public func configure(_ app: Application) throws {
    // MARK: - JSON wire format
    // Use ISO8601 dates on both encode and decode so `Date` fields round-trip
    // cleanly between Swift and JavaScript-style timestamps. We keep Swift
    // default camelCase keys — both server and iOS client mirror that so
    // `assetClass`, `dataSource`, etc. match 1:1 across the wire.
    //
    // Why not snake_case? Setting `.convertFromSnakeCase` globally also
    // affects outbound provider responses (CoinGecko's `market_data`,
    // Hyperliquid's candle arrays), which then fail to decode.
    let jsonEncoder = JSONEncoder()
    jsonEncoder.dateEncodingStrategy = .iso8601
    let jsonDecoder = JSONDecoder()
    jsonDecoder.dateDecodingStrategy = .iso8601
    ContentConfiguration.global.use(encoder: jsonEncoder, for: .json)
    ContentConfiguration.global.use(decoder: jsonDecoder, for: .json)

    // MARK: - HTTP server
    // Bind to 0.0.0.0 so the iOS app on a physical iPhone can reach us over
    // the LAN (the Mac's Wi-Fi IP). 127.0.0.1 would only be reachable from
    // the simulator. Port is still 8080 by default.
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = 8080

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
