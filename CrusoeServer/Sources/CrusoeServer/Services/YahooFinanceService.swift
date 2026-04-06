import Vapor

// Yahoo Finance unofficial API — no key needed
// Covers stocks, ETFs, commodity ETFs (GLD, SLV, USO), indices, forex pairs
// Note: unofficial, use as fallback for assets not on Hyperliquid/Finnhub
struct YahooFinanceService: MarketDataProvider {
    private let baseURL = "https://query1.finance.yahoo.com/v8/finance/chart"

    func quote(for symbol: String, on client: Client) async throws -> MarketQuote {
        let encodedSymbol = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        let uri = URI(string: "\(baseURL)/\(encodedSymbol)?interval=1d&range=2d")

        let response = try await client.get(uri) { req in
            // Yahoo requires a User-Agent header
            req.headers.add(name: .userAgent, value: "Mozilla/5.0")
        }
        guard response.status == .ok else {
            throw Abort(.badGateway, reason: "Yahoo Finance failed for \(symbol): \(response.status)")
        }

        let chart = try response.content.decode(YahooChartResponse.self)
        guard let result = chart.chart.result?.first,
              let closes = result.indicators.quote.first?.close,
              closes.count >= 1 else {
            throw Abort(.notFound, reason: "No Yahoo Finance data for \(symbol)")
        }

        let currentPrice = closes.last.flatMap { $0 } ?? 0
        let previousClose = closes.count >= 2 ? (closes[closes.count - 2] ?? currentPrice) : (result.meta.previousClose ?? currentPrice)
        let change = currentPrice - previousClose
        let changePercent = previousClose > 0 ? (change / previousClose) * 100 : 0

        return MarketQuote(
            symbol: symbol,
            price: currentPrice,
            previousClose: previousClose,
            changePercent: changePercent,
            change: change,
            source: "yahoo",
            fetchedAt: Date()
        )
    }
}

// MARK: - Response types

private struct YahooChartResponse: Content {
    let chart: YahooChart
}

private struct YahooChart: Content {
    let result: [YahooResult]?
    let error: YahooError?
}

private struct YahooError: Content {
    let code: String
    let description: String
}

private struct YahooResult: Content {
    let meta: YahooMeta
    let indicators: YahooIndicators
}

private struct YahooMeta: Content {
    let symbol: String
    let regularMarketPrice: Double?
    let previousClose: Double?
    let currency: String?
}

private struct YahooIndicators: Content {
    let quote: [YahooQuoteData]
}

private struct YahooQuoteData: Content {
    let close: [Double?]
}
