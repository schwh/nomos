import Vapor

// Finnhub — free tier: 60 req/min, US stocks, real-time quotes
// Requires free API key: https://finnhub.io (set FINNHUB_API_KEY env var)
struct FinnhubService: MarketDataProvider {
    private let baseURL = "https://finnhub.io/api/v1"

    var apiKey: String {
        Environment.get("FINNHUB_API_KEY") ?? ""
    }

    func quote(for symbol: String, on client: Client) async throws -> MarketQuote {
        guard !apiKey.isEmpty else {
            throw Abort(.serviceUnavailable, reason: "FINNHUB_API_KEY not set")
        }
        let uri = URI(string: "\(baseURL)/quote?symbol=\(symbol)&token=\(apiKey)")
        let response = try await client.get(uri)
        guard response.status == .ok else {
            throw Abort(.badGateway, reason: "Finnhub quote failed for \(symbol)")
        }
        let data = try response.content.decode(FinnhubQuote.self)
        guard data.c > 0 else {
            throw Abort(.notFound, reason: "No data for \(symbol) on Finnhub")
        }
        let change = data.c - data.pc
        let changePercent = data.pc > 0 ? (change / data.pc) * 100 : 0
        return MarketQuote(
            symbol: symbol,
            price: data.c,
            previousClose: data.pc,
            changePercent: changePercent,
            change: change,
            source: "finnhub",
            fetchedAt: Date()
        )
    }
}

private struct FinnhubQuote: Content {
    let c: Double   // current price
    let d: Double   // change
    let dp: Double  // change percent
    let h: Double   // high
    let l: Double   // low
    let o: Double   // open
    let pc: Double  // previous close
}
