import Fluent
import Vapor

final class Portfolio: Model, Content, @unchecked Sendable {
    static let schema = "portfolios"

    @ID
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "currency")
    var currency: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Children(for: \.$portfolio)
    var holdings: [Holding]

    init() {}

    init(id: UUID? = nil, name: String, currency: String = "USD") {
        self.id = id
        self.name = name
        self.currency = currency
    }
}
