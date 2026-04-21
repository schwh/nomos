import Vapor

struct NewsArticle: Content {
    let id: UUID
    let headline: String
    let summary: String
    let source: String
    let publishedAt: Date
    let url: String?
}
