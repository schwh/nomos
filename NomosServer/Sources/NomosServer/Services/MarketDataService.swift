import Vapor

// Unified quote returned to callers regardless of data source
struct MarketQuote: Content {
    let symbol: String
    let price: Double
    let previousClose: Double
    let changePercent: Double
    let change: Double
    let source: String
    let fetchedAt: Date

    var dayChange: Double { price - previousClose }
}

protocol MarketDataProvider {
    func quote(for symbol: String, on client: Client) async throws -> MarketQuote
}

// Central service — picks the right provider based on asset class / data source tag
struct MarketDataService {
    let client: Client

    func quote(symbol: String, source: String) async throws -> MarketQuote {
        switch source {
        case "hyperliquid":
            return try await HyperliquidService().quote(for: symbol, on: client)
        case "finnhub":
            return try await FinnhubService().quote(for: symbol, on: client)
        case "yahoo":
            return try await YahooFinanceService().quote(for: symbol, on: client)
        case "coingecko":
            return try await CoinGeckoService().quote(for: symbol, on: client)
        default:
            // Try Finnhub first, fall back to Yahoo
            if let q = try? await FinnhubService().quote(for: symbol, on: client) {
                return q
            }
            return try await YahooFinanceService().quote(for: symbol, on: client)
        }
    }

    // Batch fetch for an entire portfolio
    func quotes(for holdings: [(symbol: String, source: String)]) async throws -> [String: MarketQuote] {
        try await withThrowingTaskGroup(of: (String, MarketQuote)?.self) { group in
            for holding in holdings {
                group.addTask {
                    guard let q = try? await self.quote(symbol: holding.symbol, source: holding.source) else {
                        return nil
                    }
                    return (holding.symbol, q)
                }
            }
            var result: [String: MarketQuote] = [:]
            for try await pair in group {
                if let (symbol, quote) = pair {
                    result[symbol] = quote
                }
            }
            return result
        }
    }
}
