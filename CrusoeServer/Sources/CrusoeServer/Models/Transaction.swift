import Fluent
import Vapor

final class Transaction: Model, Content, @unchecked Sendable {
    static let schema = "transactions"

    @ID
    var id: UUID?

    @Parent(key: "holding_id")
    var holding: Holding

    // "buy" or "sell"
    @Field(key: "type")
    var type: String

    @Field(key: "quantity")
    var quantity: Double

    // Price per unit at time of transaction
    @Field(key: "price")
    var price: Double

    // Optional brokerage/exchange fees
    @Field(key: "fees")
    var fees: Double

    // When the trade actually occurred
    @Field(key: "executed_at")
    var executedAt: Date

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Field(key: "notes")
    var notes: String

    init() {}

    init(
        id: UUID? = nil,
        holdingID: UUID,
        type: String,
        quantity: Double,
        price: Double,
        fees: Double = 0,
        executedAt: Date = Date(),
        notes: String = ""
    ) {
        self.id = id
        self.$holding.id = holdingID
        self.type = type
        self.quantity = quantity
        self.price = price
        self.fees = fees
        self.executedAt = executedAt
        self.notes = notes
    }

    // Total cost of this transaction including fees
    var totalCost: Double { (quantity * price) + fees }
}
