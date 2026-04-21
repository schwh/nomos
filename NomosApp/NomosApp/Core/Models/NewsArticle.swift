import Foundation

struct NewsArticle: Identifiable, Codable, Hashable {
    let id: UUID
    let headline: String
    let summary: String
    let source: String
    let publishedAt: Date
    let url: String?

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: publishedAt, relativeTo: Date())
    }
}
