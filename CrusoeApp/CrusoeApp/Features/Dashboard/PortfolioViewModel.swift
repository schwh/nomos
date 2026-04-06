import SwiftUI
import Combine

@MainActor
final class PortfolioViewModel: ObservableObject {

    // MARK: - Published state

    @Published var summary: PortfolioSummary?
    @Published var portfolios: [Portfolio] = []
    @Published var selectedPortfolioID: String?
    @Published var isLoading = false
    @Published var error: APIError?

    // MARK: - Private

    private let api = APIClient.shared
    private var refreshTask: Task<Void, Never>?
    private let refreshInterval: TimeInterval = 30

    // MARK: - Initial load

    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            portfolios = try await api.fetchPortfolios()
            // Auto-select first portfolio, or previously selected one
            if selectedPortfolioID == nil {
                selectedPortfolioID = portfolios.first?.id
            }
            if let id = selectedPortfolioID {
                try await refreshSummary(portfolioID: id)
            }
            startAutoRefresh()
        } catch let err as APIError {
            error = err
        } catch {}
    }

    // MARK: - Portfolio management

    func createPortfolio(name: String, currency: String = "USD") async {
        do {
            let portfolio = try await api.createPortfolio(name: name, currency: currency)
            portfolios.append(portfolio)
            if selectedPortfolioID == nil {
                selectedPortfolioID = portfolio.id
                await loadInitialData()
            }
        } catch let err as APIError {
            error = err
        } catch {}
    }

    func deletePortfolio(_ portfolio: Portfolio) async {
        do {
            try await api.deletePortfolio(id: portfolio.id)
            portfolios.removeAll { $0.id == portfolio.id }
            if selectedPortfolioID == portfolio.id {
                selectedPortfolioID = portfolios.first?.id
                if let id = selectedPortfolioID {
                    try? await refreshSummary(portfolioID: id)
                } else {
                    summary = nil
                }
            }
        } catch let err as APIError {
            error = err
        } catch {}
    }

    // MARK: - Holdings

    func addHolding(symbol: String, assetClass: AssetClass, dataSource: DataSource) async {
        guard let pid = selectedPortfolioID else { return }
        do {
            _ = try await api.createHolding(
                portfolioID: pid,
                symbol: symbol,
                assetClass: assetClass,
                dataSource: dataSource
            )
            try await refreshSummary(portfolioID: pid)
        } catch let err as APIError {
            error = err
        } catch {}
    }

    func deleteHolding(_ holding: Holding) async {
        guard let pid = selectedPortfolioID else { return }
        do {
            try await api.deleteHolding(portfolioID: pid, holdingID: holding.id)
            try await refreshSummary(portfolioID: pid)
        } catch let err as APIError {
            error = err
        } catch {}
    }

    // MARK: - Transactions

    func addTransaction(
        holdingID: String,
        type: TransactionType,
        quantity: Double,
        price: Double,
        fees: Double = 0,
        date: Date = Date(),
        notes: String = ""
    ) async {
        guard let pid = selectedPortfolioID else { return }
        let body = CreateTransactionRequest(
            type: type.rawValue,
            quantity: quantity,
            price: price,
            fees: fees,
            executedAt: date,
            notes: notes
        )
        do {
            _ = try await api.createTransaction(holdingID: holdingID, request: body)
            try await refreshSummary(portfolioID: pid)
        } catch let err as APIError {
            error = err
        } catch {}
    }

    func deleteTransaction(_ transaction: Transaction) async {
        guard let pid = selectedPortfolioID else { return }
        do {
            try await api.deleteTransaction(holdingID: transaction.holdingID, transactionID: transaction.id)
            try await refreshSummary(portfolioID: pid)
        } catch let err as APIError {
            error = err
        } catch {}
    }

    // MARK: - Refresh

    func refreshSummary(portfolioID: String) async throws {
        summary = try await api.fetchPortfolioSummary(id: portfolioID)
    }

    func manualRefresh() async {
        guard let id = selectedPortfolioID else { return }
        isLoading = true
        defer { isLoading = false }
        try? await refreshSummary(portfolioID: id)
    }

    // MARK: - Auto-refresh (polls every 30s while app is in foreground)

    private func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(30e9))
                guard let self, let id = self.selectedPortfolioID else { continue }
                try? await self.refreshSummary(portfolioID: id)
            }
        }
    }

    // MARK: - Convenience computed

    var currentHoldings: [HoldingSummary] {
        summary?.holdings ?? []
    }

    var totalValue: Double {
        summary?.totalValue ?? 0
    }

    var totalDayChange: Double {
        summary?.totalDayChange ?? 0
    }

    var isDayPositive: Bool {
        totalDayChange >= 0
    }
}
