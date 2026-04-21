import Vapor

struct MarketController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let market = routes.grouped("market")
        market.get("quote", ":symbol", use: quote)
        market.get("assets", "hyperliquid", use: hyperliquidAssets)
        market.get("news", use: news)
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

    // GET /api/v1/market/news — mocked "non noisy" curated news
    func news(req: Request) async throws -> [NewsArticle] {
        let now = Date()
        return [
            NewsArticle(
                id: UUID(),
                headline: "Fed Maintains Interest Rates in Latest Policy Meeting",
                summary: "The Federal Reserve opted to hold its benchmark rate steady, signaling a data-dependent approach for the coming months as inflation shows signs of cooling.",
                source: "Macro Digest",
                publishedAt: now.addingTimeInterval(-3600), // 1 hr ago
                url: nil
            ),
            NewsArticle(
                id: UUID(),
                headline: "Tech Giants Exceed Earnings Expectations",
                summary: "Leading technology companies reported strong quarterly earnings, driven by robust cloud computing demand and stabilizing ad revenue.",
                source: "Market Watch",
                publishedAt: now.addingTimeInterval(-7200), // 2 hrs ago
                url: nil
            ),
            NewsArticle(
                id: UUID(),
                headline: "Treasury Yields Stabilize Amid Economic Optimism",
                summary: "Bond markets saw diminished volatility today as investors digested a series of positive employment and manufacturing data points.",
                source: "Daily Briefing",
                publishedAt: now.addingTimeInterval(-10800), // 3 hrs ago
                url: nil
            ),
            NewsArticle(
                id: UUID(),
                headline: "OPEC+ Announces Continued Production Cuts",
                summary: "The coalition of oil producers confirmed an extension of voluntary output reductions, aiming to balance sluggish global demand forecasts.",
                source: "Commodity Insights",
                publishedAt: now.addingTimeInterval(-86400), // 1 day ago
                url: nil
            )
        ]
    }
}
