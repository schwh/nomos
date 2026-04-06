import SwiftUI

struct HoldingDetailView: View {
    let item: HoldingSummary
    @EnvironmentObject private var vm: PortfolioViewModel
    @State private var transactions: [Transaction] = []
    @State private var showAddTransaction = false
    @State private var isLoading = true

    var body: some View {
        List {
            // Live stats header
            Section {
                statRow("Price", item.quote?.price.formatted(.currency(code: "USD")) ?? "—")
                statRow("Market Value", item.marketValue.formatted(.currency(code: "USD")))
                statRow("Avg Cost", item.holding.avgCostBasis.formatted(.currency(code: "USD")))
                statRow("Quantity", String(format: "%.6g", item.holding.quantity))
                statRow("Unrealized P&L",
                    item.unrealizedPnL.formatted(.currency(code: "USD")),
                    valueColor: item.isPositive ? .green : .red
                )
                statRow("Day Change",
                    item.dayChange.formatted(.currency(code: "USD")),
                    valueColor: item.isDayPositive ? .green : .red
                )
            } header: {
                Text("Live Summary")
            }

            // Transaction history
            Section {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else if transactions.isEmpty {
                    Text("No transactions yet.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(transactions) { txn in
                        TransactionRow(txn: txn)
                    }
                    .onDelete { indexSet in
                        Task {
                            for i in indexSet {
                                await vm.deleteTransaction(transactions[i])
                            }
                            await loadTransactions()
                        }
                    }
                }
            } header: {
                Text("Transaction History")
            }
        }
        .navigationTitle(item.symbol)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddTransaction = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView(holdingID: item.holding.id, symbol: item.symbol)
                .onDisappear { Task { await loadTransactions() } }
        }
        .task { await loadTransactions() }
    }

    private func loadTransactions() async {
        isLoading = true
        transactions = (try? await APIClient.shared.fetchTransactions(holdingID: item.holding.id)) ?? []
        isLoading = false
    }

    private func statRow(_ label: String, _ value: String, valueColor: Color = .primary) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).foregroundStyle(valueColor).fontWeight(.medium)
        }
    }
}

private struct TransactionRow: View {
    let txn: Transaction

    var body: some View {
        HStack {
            Image(systemName: txn.type == .buy ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundStyle(txn.type == .buy ? .green : .red)

            VStack(alignment: .leading, spacing: 2) {
                Text(txn.type.displayName)
                    .font(.subheadline.weight(.medium))
                Text(txn.executedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(txn.totalCost.formatted(.currency(code: "USD")))
                    .font(.subheadline.weight(.semibold))
                Text("\(String(format: "%.4g", txn.quantity)) @ \(txn.price.formatted(.currency(code: "USD")))")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
