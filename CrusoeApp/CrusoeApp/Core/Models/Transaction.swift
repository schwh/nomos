import Foundation

struct Transaction: Identifiable, Codable {
    let id: String
    let holdingID: String
    let type: TransactionType
    let quantity: Double
    let price: Double
    let fees: Double
    let totalCost: Double
    let executedAt: Date
    let notes: String
}

enum TransactionType: String, Codable, CaseIterable {
    case buy  = "buy"
    case sell = "sell"

    var displayName: String { rawValue.capitalized }
    var isPositive: Bool { self == .buy }
}

// Request body sent when creating a transaction
struct CreateTransactionRequest: Encodable {
    let type: String
    let quantity: Double
    let price: Double
    let fees: Double
    let executedAt: Date
    let notes: String
}
