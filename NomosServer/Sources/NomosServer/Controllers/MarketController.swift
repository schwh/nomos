import Vapor

struct MarketController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let market = routes.grouped("market")
        market.get("quote", ":symbol", use: quote)
        market.get("assets", "hyperliquid", use: hyperliquidAssets)
    }

    // GET /api/v1/market/quote/:symbol?source=hyperliquid|finnhub|yahoo|coingecko
    func quote(req: Request) async throws -> MarketQuote {
        guard let symbol = req.parameters.get("symbol") else {
            throw Abort(.badRequest)
        }
        let source = req.query[String.self, at: "source"] ?? "auto"
        let service = MarketDataService(client: req.client)
        return try await service.quote(symbol: symbol.uppercased(), source: source)
    }

    // GET /api/v1/market/assets/hyperliquid — list all tradeable perps
    func hyperliquidAssets(req: Request) async throws -> [HyperliquidAsset] {
        return try await HyperliquidService().fetchAvailableAssets(on: req.client)
    }
}
