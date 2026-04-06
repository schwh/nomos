import Vapor

// Hyperliquid — free, no API key, covers 100+ crypto & stock perpetuals
// REST: https://api.hyperliquid.xyz/info
// WebSocket: wss://api.hyperliquid.xyz/ws
struct HyperliquidService: MarketDataProvider {
    private let baseURL = "https://api.hyperliquid.xyz/info"

    func quote(for symbol: String, on client: Client) async throws -> MarketQuote {
        // Fetch all mid-prices in one call (most efficient)
        let allMids = try await fetchAllMids(on: client)

        guard let midPrice = allMids[symbol],
              let price = Double(midPrice) else {
            throw Abort(.notFound, reason: "Symbol \(symbol) not found on Hyperliquid")
        }

        // Fetch 24h candle for previous close
        let prevClose = try await fetchPreviousClose(symbol: symbol, on: client)
        let change = price - prevClose
        let changePercent = prevClose > 0 ? (change / prevClose) * 100 : 0

        return MarketQuote(
            symbol: symbol,
            price: price,
            previousClose: prevClose,
            changePercent: changePercent,
            change: change,
            source: "hyperliquid",
            fetchedAt: Date()
        )
    }

    // Returns { "BTC": "65432.1", "ETH": "3210.5", ... }
    func fetchAllMids(on client: Client) async throws -> [String: String] {
        let body = AllMidsRequest(type: "allMids")
        let response = try await client.post(URI(string: baseURL)) { req in
            req.headers.contentType = .json
            try req.content.encode(body)
        }
        guard response.status == .ok else {
            throw Abort(.badGateway, reason: "Hyperliquid allMids failed: \(response.status)")
        }
        return try response.content.decode([String: String].self)
    }

    func fetchAvailableAssets(on client: Client) async throws -> [HyperliquidAsset] {
        struct MetaRequest: Content { let type: String }
        let response = try await client.post(URI(string: baseURL)) { req in
            req.headers.contentType = .json
            try req.content.encode(MetaRequest(type: "meta"))
        }
        let meta = try response.content.decode(HyperliquidMetaResponse.self)
        return meta.universe.map { HyperliquidAsset(name: $0.name, szDecimals: $0.szDecimals, maxLeverage: $0.maxLeverage) }
    }

    private func fetchPreviousClose(symbol: String, on client: Client) async throws -> Double {
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-86400)
        let request = CandleRequest(
            type: "candleSnapshot",
            req: CandleRequest.CandleParams(
                coin: symbol,
                interval: "1d",
                startTime: Int(oneDayAgo.timeIntervalSince1970 * 1000),
                endTime: Int(now.timeIntervalSince1970 * 1000)
            )
        )
        let response = try await client.post(URI(string: baseURL)) { req in
            req.headers.contentType = .json
            try req.content.encode(request)
        }
        let candles = try response.content.decode([HyperliquidCandle].self)
        // Previous close is the open of the most recent daily candle
        return Double(candles.last?.o ?? "0") ?? 0
    }
}

// MARK: - Request/Response types

private struct AllMidsRequest: Content {
    let type: String
}

private struct CandleRequest: Content {
    let type: String
    let req: CandleParams
    struct CandleParams: Content {
        let coin: String
        let interval: String
        let startTime: Int
        let endTime: Int
    }
}

struct HyperliquidCandle: Content {
    let t: Int     // open time (ms)
    let T: Int     // close time (ms)
    let o: String  // open
    let c: String  // close
    let h: String  // high
    let l: String  // low
    let v: String  // volume
    let n: Int     // number of trades
}

struct HyperliquidAsset: Content {
    let name: String
    let szDecimals: Int
    let maxLeverage: Int
}

private struct HyperliquidMetaResponse: Content {
    let universe: [UniverseItem]
    struct UniverseItem: Content {
        let name: String
        let szDecimals: Int
        let maxLeverage: Int
    }
}
