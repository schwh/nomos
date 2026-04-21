import SwiftUI

@MainActor
final class NewsViewModel: ObservableObject {
    @Published var articles: [NewsArticle] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    func fetchNews() async {
        guard articles.isEmpty else { return } // Basic caching for the session
        
        isLoading = true
        errorMessage = nil
        
        do {
            self.articles = try await APIClient.shared.fetchNews()
        } catch {
            self.errorMessage = "Failed to load news: \(error.localizedDescription)"
        }
        
        isLoading = false
    }

    func manualRefresh() async {
        isLoading = true
        errorMessage = nil
        do {
            self.articles = try await APIClient.shared.fetchNews()
        } catch {
            self.errorMessage = "Failed to load news: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
