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
            // First-run bootstrap: create a default portfolio so "Add Holding"
            // has somewhere to write to. Without this the button silently no-ops.
            if portfolios.isEmpty {
                let created = try await api.createPortfolio(name: "Main", currency: "USD")
                portfolios = [created]
            }
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

    /// If loadInitialData silently failed (e.g. server wasn't up at launch)
    /// we'd have no portfolio and every mutation would no-op. Re-fetch or
    /// create one on demand so the user's action still lands.
    private func requirePortfolioID() async throws -> String {
        if let pid = selectedPortfolioID { return pid }
        let existing = try await api.fetchPortfolios()
        if let first = existing.first {
            portfolios = existing
            selectedPortfolioID = first.id
            return first.id
        }
        let created = try await api.createPortfolio(name: "Main", currency: "USD")
        portfolios = [created]
        selectedPortfolioID = created.id
        return created.id
    }

    /// Throws so callers can surface failures (the Add sheet shows an inline
    /// error instead of silently closing).
    func addHolding(symbol: String, assetClass: AssetClass, dataSource: DataSource) async throws {
        let pid = try await requirePortfolioID()
        _ = try await api.createHolding(
            portfolioID: pid,
            symbol: symbol,
            assetClass: assetClass,
            dataSource: dataSource
        )
        try await refreshSummary(portfolioID: pid)
    }

    /// One-shot: add (quantity) shares of `symbol` at `price`. Creates the
    /// holding if it doesn't exist and seeds it with a BUY transaction.
    func addPosition(
        symbol: String,
        assetClass: AssetClass,
        dataSource: DataSource,
        quantity: Double,
        price: Double,
        fees: Double = 0,
        date: Date = Date(),
        notes: String = ""
    ) async throws {
        let pid = try await requirePortfolioID()
        _ = try await api.createPosition(
            portfolioID: pid,
            symbol: symbol,
            assetClass: assetClass,
            dataSource: dataSource,
            quantity: quantity,
            price: price,
            fees: fees,
            date: date,
            notes: notes
        )
        try await refreshSummary(portfolioID: pid)
    }

    /// Direct override of a holding's shares and/or avg cost — for quick
    /// corrections that bypass the transaction ledger.
    func updateHolding(holdingID: String, quantity: Double?, avgCostBasis: Double?) async {
        guard let pid = selectedPortfolioID else { return }
        do {
            _ = try await api.updateHolding(
                portfolioID: pid,
                holdingID: holdingID,
                quantity: quantity,
                avgCostBasis: avgCostBasis
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
