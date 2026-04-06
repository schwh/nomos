import SwiftUI

// Activity tab — shows all transactions across all holdings in the selected portfolio
struct TransactionListView: View {
    @EnvironmentObject private var vm: PortfolioViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.currentHoldings) { item in
                    if !item.holding.id.isEmpty {
                        HoldingTransactionSection(item: item)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Activity")
            .overlay {
                if vm.currentHoldings.isEmpty {
                    ContentUnavailableView(
                        "No Activity",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Add holdings and transactions to see activity here.")
                    )
                }
            }
        }
    }
}

private struct HoldingTransactionSection: View {
    let item: HoldingSummary
    @State private var transactions: [Transaction] = []
    @State private var isExpanded = true

    var body: some View {
        Section(isExpanded: $isExpanded) {
            ForEach(transactions) { txn in
                HStack {
                    Image(systemName: txn.type == .buy ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                        .foregroundStyle(txn.type == .buy ? .green : .red)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(txn.type.displayName) \(String(format: "%.4g", txn.quantity)) \(item.symbol)")
                            .font(.subheadline)
                        Text(txn.executedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(txn.totalCost.formatted(.currency(code: "USD")))
                        .font(.subheadline.weight(.medium))
                }
            }
        } header: {
            Text(item.symbol)
        }
        .task { await loadTransactions() }
    }

    private func loadTransactions() async {
        transactions = (try? await APIClient.shared.fetchTransactions(holdingID: item.holding.id)) ?? []
    }
}
