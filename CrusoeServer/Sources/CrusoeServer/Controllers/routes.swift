import Vapor

func routes(_ app: Application) throws {
    let api = app.grouped("api", "v1")

    try api.register(collection: PortfolioController())
    try api.register(collection: HoldingController())
    try api.register(collection: TransactionController())
    try api.register(collection: MarketController())
    try api.register(collection: AnalysisController())
}
