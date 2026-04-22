import Foundation

enum APIEndpoint {
    // MARK: - Portfolios
    case portfolios
    case portfolio(id: String)
    case portfolioSummary(id: String)
    case portfolioAnalysis(id: String)

    // MARK: - Holdings
    case holdings(portfolioID: String)
    case holding(portfolioID: String, holdingID: String)
    case positions(portfolioID: String)

    // MARK: - Transactions
    case transactions(holdingID: String)
    case transaction(holdingID: String, txnID: String)

    // MARK: - Market
    case quote(symbol: String, source: String)
    case hyperliquidAssets
    case news

    var path: String {
        switch self {
        case .portfolios:
            return "/api/v1/portfolios"
        case .portfolio(let id):
            return "/api/v1/portfolios/\(id)"
        case .portfolioSummary(let id):
            return "/api/v1/portfolios/\(id)/summary"
        case .portfolioAnalysis(let id):
            return "/api/v1/portfolios/\(id)/analysis"
        case .holdings(let pid):
            return "/api/v1/portfolios/\(pid)/holdings"
        case .holding(let pid, let hid):
            return "/api/v1/portfolios/\(pid)/holdings/\(hid)"
        case .positions(let pid):
            return "/api/v1/portfolios/\(pid)/positions"
        case .transactions(let hid):
            return "/api/v1/holdings/\(hid)/transactions"
        case .transaction(let hid, let tid):
            return "/api/v1/holdings/\(hid)/transactions/\(tid)"
        case .quote(let symbol, let source):
            return "/api/v1/market/quote/\(symbol)?source=\(source)"
        case .hyperliquidAssets:
            return "/api/v1/market/assets/hyperliquid"
        case .news:
            return "/api/v1/market/news"
        }
    }
}
