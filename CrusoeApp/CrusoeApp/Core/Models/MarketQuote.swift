import Foundation

struct MarketQuote: Codable {
    let symbol: String
    let price: Double
    let previousClose: Double
    let changePercent: Double
    let change: Double
    let source: String
    let fetchedAt: Date

    var isPositive: Bool { change >= 0 }
    var formattedChange: String {
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", changePercent))%"
    }
}
