import SwiftUI

@MainActor
final class AnalysisViewModel: ObservableObject {
    @Published var analysis: PortfolioAnalysis?
    @Published var isLoading = false
    @Published var error: APIError?

    private let api = APIClient.shared

    func load(portfolioID: String) async {
        guard !portfolioID.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            analysis = try await api.fetchPortfolioAnalysis(id: portfolioID)
        } catch let err as APIError {
            error = err
        } catch {}
    }

    func refresh(portfolioID: String) async {
        await load(portfolioID: portfolioID)
    }
}
