import SwiftUI

struct HoldingDetailView: View {
    let item: HoldingSummary
    @EnvironmentObject private var vm: PortfolioViewModel
    @State private var transactions: [Transaction] = []
    @State private var showAddTransaction = false
    @State private var showEditPosition = false
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
                Menu {
                    Button {
                        showAddTransaction = true
                    } label: {
                        Label("Add Transaction", systemImage: "plus.circle")
                    }
                    Button {
                        showEditPosition = true
                    } label: {
                        Label("Edit Position", systemImage: "slider.horizontal.3")
                    }
                    Button(role: .destructive) {
                        Task {
                            await vm.deleteHolding(item.holding)
                        }
                    } label: {
                        Label("Remove Holding", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView(holdingID: item.holding.id, symbol: item.symbol)
                .onDisappear { Task { await loadTransactions() } }
        }
        .sheet(isPresented: $showEditPosition) {
            EditPositionView(holding: item.holding)
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

// Quick override for a holding's shares / avg cost. Bypasses the transaction
// ledger — useful for correcting bad imports or seed data.
private struct EditPositionView: View {
    let holding: Holding
    @EnvironmentObject private var vm: PortfolioViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var quantity: String
    @State private var avgCost: String
    @State private var isSubmitting = false

    init(holding: Holding) {
        self.holding = holding
        _quantity = State(initialValue: holding.quantity > 0 ? String(holding.quantity) : "")
        _avgCost = State(initialValue: holding.avgCostBasis > 0 ? String(holding.avgCostBasis) : "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Symbol") { Text(holding.symbol).foregroundStyle(.secondary) }
                    TextField("Shares", text: $quantity)
                        .keyboardType(.decimalPad)
                    TextField("Avg cost / share", text: $avgCost)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Override")
                } footer: {
                    Text("Writes directly to the holding — does not create a transaction. Leave a field blank to keep its current value.")
                }
            }
            .navigationTitle("Edit \(holding.symbol)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { submit() }
                        .disabled(isSubmitting || !hasChange)
                }
            }
            .overlay {
                if isSubmitting { LoadingView(message: "Saving...") }
            }
        }
    }

    private var hasChange: Bool {
        Double(quantity) != nil || Double(avgCost) != nil
    }

    private func submit() {
        isSubmitting = true
        Task {
            await vm.updateHolding(
                holdingID: holding.id,
                quantity: Double(quantity),
                avgCostBasis: Double(avgCost)
            )
            isSubmitting = false
            dismiss()
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
