import SwiftUI

struct AddTransactionView: View {
    let holdingID: String
    let symbol: String

    @EnvironmentObject private var vm: PortfolioViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var type: TransactionType = .buy
    @State private var quantity = ""
    @State private var price = ""
    @State private var fees = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var isSubmitting = false

    private var isValid: Bool {
        Double(quantity) != nil && Double(price) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Trade") {
                    Picker("Type", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)

                    LabeledContent("Symbol") { Text(symbol).foregroundStyle(.secondary) }

                    TextField("Quantity", text: $quantity)
                        .keyboardType(.decimalPad)
                    TextField("Price per unit", text: $price)
                        .keyboardType(.decimalPad)
                    TextField("Fees (optional)", text: $fees)
                        .keyboardType(.decimalPad)
                }

                Section("Details") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    TextField("Notes (optional)", text: $notes)
                }

                if let qty = Double(quantity), let prc = Double(price) {
                    Section("Summary") {
                        LabeledContent("Total") {
                            Text((qty * prc + (Double(fees) ?? 0)).formatted(.currency(code: "USD")))
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .navigationTitle(type == .buy ? "Buy \(symbol)" : "Sell \(symbol)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { submit() }
                        .disabled(!isValid || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting { LoadingView(message: "Saving...") }
            }
        }
    }

    private func submit() {
        guard let qty = Double(quantity), let prc = Double(price) else { return }
        isSubmitting = true
        Task {
            await vm.addTransaction(
                holdingID: holdingID,
                type: type,
                quantity: qty,
                price: prc,
                fees: Double(fees) ?? 0,
                date: date,
                notes: notes
            )
            isSubmitting = false
            dismiss()
        }
    }
}
