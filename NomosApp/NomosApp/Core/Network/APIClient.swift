import Foundation

// MARK: - API Error

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case httpError(statusCode: Int, message: String)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received from server"
        case .httpError(let code, let msg):
            return "Server error \(code): \(msg)"
        case .decodingError(let err):
            return "Failed to decode response: \(err.localizedDescription)"
        case .networkError(let err):
            return "Network error: \(err.localizedDescription)"
        }
    }
}

// MARK: - API Client

final class APIClient {
    static let shared = APIClient()

    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        // In development, point at local Vapor server.
        // - Simulator can hit "http://localhost:8080" (same machine).
        // - A physical iPhone needs the Mac's LAN IP, since `localhost` on the
        //   phone means the phone itself.
        // Override by setting API_BASE_URL in the Xcode scheme's environment.
        // The hardcoded fallback below targets the Mac's current Wi-Fi IP —
        // update it if your Mac's address changes (run `ipconfig getifaddr en0`).
        self.baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"]
            ?? "http://192.168.68.103:8080"

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)

        // Server uses Swift-native camelCase keys (matches its Content DTOs).
        // We mirror that here so property names round-trip 1:1 without any
        // snake_case translation — keeps acronyms like `holdingID` intact.
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Core request method

    private func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            req.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(statusCode: http.statusCode, message: message)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // Discard-response variant (for DELETE, etc.)
    private func requestEmpty(
        _ endpoint: APIEndpoint,
        method: String,
        body: Encodable? = nil
    ) async throws {
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            req.httpBody = try encoder.encode(AnyEncodable(body))
        }
        let (data, response) = try await session.data(for: req)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(statusCode: http.statusCode, message: message)
        }
    }

    // MARK: - Portfolio endpoints

    func fetchPortfolios() async throws -> [Portfolio] {
        try await request(.portfolios)
    }

    func createPortfolio(name: String, currency: String = "USD") async throws -> Portfolio {
        struct Body: Encodable { let name: String; let currency: String }
        return try await request(.portfolios, method: "POST", body: Body(name: name, currency: currency))
    }

    func deletePortfolio(id: String) async throws {
        try await requestEmpty(.portfolio(id: id), method: "DELETE")
    }

    func fetchPortfolioSummary(id: String) async throws -> PortfolioSummary {
        try await request(.portfolioSummary(id: id))
    }

    func fetchPortfolioAnalysis(id: String) async throws -> PortfolioAnalysis {
        try await request(.portfolioAnalysis(id: id))
    }

    // MARK: - Holding endpoints

    func fetchHoldings(portfolioID: String) async throws -> [Holding] {
        try await request(.holdings(portfolioID: portfolioID))
    }

    func createHolding(
        portfolioID: String,
        symbol: String,
        assetClass: AssetClass,
        dataSource: DataSource
    ) async throws -> Holding {
        struct Body: Encodable { let symbol: String; let assetClass: String; let dataSource: String }
        return try await request(
            .holdings(portfolioID: portfolioID),
            method: "POST",
            body: Body(symbol: symbol, assetClass: assetClass.rawValue, dataSource: dataSource.rawValue)
        )
    }

    func deleteHolding(portfolioID: String, holdingID: String) async throws {
        try await requestEmpty(.holding(portfolioID: portfolioID, holdingID: holdingID), method: "DELETE")
    }

    func updateHolding(
        portfolioID: String,
        holdingID: String,
        quantity: Double?,
        avgCostBasis: Double?
    ) async throws -> Holding {
        struct Body: Encodable { let quantity: Double?; let avgCostBasis: Double? }
        return try await request(
            .holding(portfolioID: portfolioID, holdingID: holdingID),
            method: "PATCH",
            body: Body(quantity: quantity, avgCostBasis: avgCostBasis)
        )
    }

    func createPosition(
        portfolioID: String,
        symbol: String,
        assetClass: AssetClass,
        dataSource: DataSource,
        quantity: Double,
        price: Double,
        fees: Double,
        date: Date,
        notes: String
    ) async throws -> Holding {
        struct Body: Encodable {
            let symbol: String
            let assetClass: String
            let dataSource: String
            let quantity: Double
            let price: Double
            let fees: Double
            let executedAt: Date
            let notes: String
        }
        return try await request(
            .positions(portfolioID: portfolioID),
            method: "POST",
            body: Body(
                symbol: symbol,
                assetClass: assetClass.rawValue,
                dataSource: dataSource.rawValue,
                quantity: quantity,
                price: price,
                fees: fees,
                executedAt: date,
                notes: notes
            )
        )
    }

    // MARK: - Transaction endpoints

    func fetchTransactions(holdingID: String) async throws -> [Transaction] {
        try await request(.transactions(holdingID: holdingID))
    }

    func createTransaction(holdingID: String, request body: CreateTransactionRequest) async throws -> Transaction {
        try await request(.transactions(holdingID: holdingID), method: "POST", body: body)
    }

    func deleteTransaction(holdingID: String, transactionID: String) async throws {
        try await requestEmpty(.transaction(holdingID: holdingID, txnID: transactionID), method: "DELETE")
    }

    // MARK: - Market endpoints

    func fetchQuote(symbol: String, source: String) async throws -> MarketQuote {
        try await request(.quote(symbol: symbol, source: source))
    }

    func fetchNews() async throws -> [NewsArticle] {
        try await request(.news)
    }
}

// MARK: - Type-erased Encodable helper

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ value: Encodable) { _encode = value.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}
