import SwiftUI

struct AddHoldingView: View {
    @EnvironmentObject private var vm: PortfolioViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var symbol = ""
    @State private var assetClass: AssetClass = .stock
    @State private var dataSource: DataSource = .finnhub
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Asset") {
                    TextField("Symbol (e.g. AAPL, BTC)", text: $symbol)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    Picker("Asset Class", selection: $assetClass) {
                        ForEach(AssetClass.allCases, id: \.self) { ac in
                            Label(ac.displayName, systemImage: ac.icon).tag(ac)
                        }
                    }
                    .onChange(of: assetClass) { _, newValue in
                        dataSource = DataSource.defaultFor(newValue)
                    }
                }

                Section("Data Source") {
                    Picker("Source", selection: $dataSource) {
                        ForEach(DataSource.allCases, id: \.self) { ds in
                            Text(ds.displayName).tag(ds)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Add Holding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { submit() }
                        .disabled(symbol.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting { LoadingView(message: "Adding...") }
            }
        }
    }

    private func submit() {
        isSubmitting = true
        Task {
            await vm.addHolding(
                symbol: symbol.trimmingCharacters(in: .whitespaces).uppercased(),
                assetClass: assetClass,
                dataSource: dataSource
            )
            isSubmitting = false
            dismiss()
        }
    }
}
