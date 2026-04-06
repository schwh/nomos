import Vapor

// CoinGecko — free, no key needed for basic endpoints
// Use as fallback for spot crypto not on Hyperliquid
struct CoinGeckoService: MarketDataProvider {
    private let baseURL = "https://api.coingecko.com/api/v3"

    // Maps common ticker symbols to CoinGecko IDs
    private let symbolToID: [String: String] = [
        "BTC": "bitcoin", "ETH": "ethereum", "SOL": "solana",
        "BNB": "binancecoin", "XRP": "ripple", "ADA": "cardano",
        "DOGE": "dogecoin", "AVAX": "avalanche-2", "DOT": "polkadot",
        "MATIC": "matic-network", "LINK": "chainlink", "UNI": "uniswap",
        "LTC": "litecoin", "ATOM": "cosmos", "XLM": "stellar",
    ]

    func quote(for symbol: String, on client: Client) async throws -> MarketQuote {
        let coinID = symbolToID[symbol.uppercased()] ?? symbol.lowercased()
        let uri = URI(string: "\(baseURL)/coins/\(coinID)?localization=false&tickers=false&community_data=false&developer_data=false")

        let response = try await client.get(uri) { req in
            req.headers.add(name: .userAgent, value: "NomosApp/1.0")
        }
        guard response.status == .ok else {
            throw Abort(.badGateway, reason: "CoinGecko failed for \(symbol): \(response.status)")
        }

        let data = try response.content.decode(CoinGeckoCoinResponse.self)
        let price = data.market_data.current_price["usd"] ?? 0
        let prevClose = price - (data.market_data.price_change_24h ?? 0)
        let changePercent = data.market_data.price_change_percentage_24h ?? 0

        return MarketQuote(
            symbol: symbol.uppercased(),
            price: price,
            previousClose: prevClose,
            changePercent: changePercent,
            change: data.market_data.price_change_24h ?? 0,
            source: "coingecko",
            fetchedAt: Date()
        )
    }
}

private struct CoinGeckoCoinResponse: Content {
    let id: String
    let symbol: String
    let market_data: MarketData

    struct MarketData: Content {
        let current_price: [String: Double]
        let price_change_24h: Double?
        let price_change_percentage_24h: Double?
    }
}
