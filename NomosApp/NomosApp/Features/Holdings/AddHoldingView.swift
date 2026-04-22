import SwiftUI

// Compact glass card shown as an overlay, not a full-screen sheet.
// The parent (HoldingsView) drives the expand/collapse transition anchored
// to the + button, giving a macOS-tab-opening feel.
//
// Two flows in one form:
//   • Leave quantity + price blank → symbol-only watchlist add.
//   • Fill both → server creates the holding AND seeds a BUY transaction
//     in a single atomic call (POST /portfolios/:id/positions).
struct AddHoldingCard: View {
    @EnvironmentObject private var vm: PortfolioViewModel
    @EnvironmentObject private var theme: ThemeManager

    var onCancel: () -> Void
    var onSubmitted: () -> Void

    @State private var symbol = ""
    @State private var assetClass: AssetClass = .stock
    @State private var quantity = ""
    @State private var price = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @FocusState private var focus: Field?

    private enum Field { case symbol, quantity, price }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            symbolField
            assetClassPicker
            positionFields
            totalRow
            footerHint
            if let errorMessage { errorBanner(errorMessage) }
            actions
        }
        .padding(22)
        .background { panelBackground }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            theme.current.accent.opacity(0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.45), radius: 40, y: 20)
        .shadow(color: theme.current.accent.opacity(0.18), radius: 30)
        .onAppear { focus = .symbol }
        // Decimal keyboards have no return key, so we attach a Done bar above
        // the keyboard that dismisses focus and uncovers the Add button.
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    focus = nil
                } label: {
                    Text("Done").fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("New Asset")
                    .trackedLabel()
                    .foregroundStyle(theme.current.accent)
                Text("Add Holding")
                    .font(.headlineMd)
                    .foregroundStyle(Color.onSurface)
            }
            Spacer()
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.onSurfaceVariant)
                    .frame(width: 28, height: 28)
                    .background(Color.surfaceContainerHighest, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var symbolField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Symbol")
                .trackedLabel()
                .foregroundStyle(Color.secondaryText)

            TextField("", text: $symbol, prompt: Text("AAPL, BTC, GLD, GC=F...").foregroundColor(Color.secondaryText))
                .focused($focus, equals: .symbol)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(.titleLg)
                .foregroundStyle(Color.onSurface)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.surfaceContainerHighest.opacity(0.6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            focus == .symbol ? theme.current.accent.opacity(0.55)
                                             : Color.outlineVariant.opacity(0.15),
                            lineWidth: 1
                        )
                }
                .animation(.easeOut(duration: 0.15), value: focus)
        }
    }

    private var assetClassPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Asset Class")
                .trackedLabel()
                .foregroundStyle(Color.secondaryText)

            HStack(spacing: 8) {
                ForEach(AssetClass.allCases, id: \.self) { ac in
                    classChip(ac)
                }
            }
        }
    }

    private func classChip(_ ac: AssetClass) -> some View {
        let selected = assetClass == ac
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                assetClass = ac
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: ac.icon)
                    .font(.system(size: 14, weight: selected ? .semibold : .regular))
                Text(ac.displayName)
                    .font(.labelLg)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(theme.current.accent.opacity(0.18))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(theme.current.accent.opacity(0.45), lineWidth: 1)
                        }
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.surfaceContainerHighest.opacity(0.5))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.outlineVariant.opacity(0.12), lineWidth: 1)
                        }
                }
            }
            .foregroundStyle(selected ? theme.current.accent : Color.onSurfaceVariant)
        }
        .buttonStyle(.plain)
    }

    private var positionFields: some View {
        HStack(spacing: 10) {
            numericField(label: "Shares", placeholder: "0", text: $quantity, field: .quantity)
            numericField(label: "Price / unit", placeholder: "0.00", text: $price, field: .price)
        }
    }

    private func numericField(label: String, placeholder: String, text: Binding<String>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .trackedLabel()
                .foregroundStyle(Color.secondaryText)
            TextField("", text: text, prompt: Text(placeholder).foregroundColor(Color.secondaryText))
                .focused($focus, equals: field)
                .keyboardType(.decimalPad)
                .font(.titleMd)
                .foregroundStyle(Color.onSurface)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.surfaceContainerHighest.opacity(0.6), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            focus == field ? theme.current.accent.opacity(0.55)
                                           : Color.outlineVariant.opacity(0.15),
                            lineWidth: 1
                        )
                }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var totalRow: some View {
        if let qty = Double(quantity), let prc = Double(price), qty > 0, prc > 0 {
            HStack {
                Text("Total cost")
                    .font(.labelLg)
                    .foregroundStyle(Color.secondaryText)
                Spacer()
                Text((qty * prc).formatted(.currency(code: "USD")))
                    .font(.titleMd)
                    .foregroundStyle(theme.current.accent)
            }
            .padding(.horizontal, 4)
        }
    }

    private var footerHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .semibold))
            Text(hintText)
                .font(.labelLg)
        }
        .foregroundStyle(Color.secondaryText)
    }

    private var hintText: String {
        if hasQuantityAndPrice {
            return "Seeds a BUY transaction · \(DataSource.defaultFor(assetClass).displayName) quotes"
        }
        return "Leave shares blank to just track the symbol · \(DataSource.defaultFor(assetClass).displayName) quotes"
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.titleMd)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(Color.onSurfaceVariant)
                    .background(Color.surfaceContainerHighest.opacity(0.5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: submit) {
                HStack(spacing: 6) {
                    if isSubmitting {
                        ProgressView().tint(Color.onPrimary)
                    } else {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                    Text(submitLabel)
                        .font(.titleMd)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(Color.black)
                .background(theme.current.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: theme.current.accent.opacity(0.35), radius: 10)
                .opacity(canSubmit ? 1 : 0.5)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit || isSubmitting)
        }
    }

    private var panelBackground: some View {
        ZStack {
            Color.surfaceContainer
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.75)
            LinearGradient(
                colors: [
                    theme.current.accent.opacity(0.12),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Validation

    private var trimmedSymbol: String {
        symbol.trimmingCharacters(in: .whitespaces).uppercased()
    }

    private var hasQuantityAndPrice: Bool {
        (Double(quantity) ?? 0) > 0 && (Double(price) ?? 0) > 0
    }

    private var canSubmit: Bool {
        !trimmedSymbol.isEmpty
    }

    private var submitLabel: String {
        if isSubmitting { return "Adding..." }
        return hasQuantityAndPrice ? "Buy \(trimmedSymbol)" : "Track"
    }

    // MARK: - Actions

    private func submit() {
        guard canSubmit else { return }
        isSubmitting = true
        errorMessage = nil
        Task {
            let source = DataSource.defaultFor(assetClass)
            do {
                if let qty = Double(quantity), let prc = Double(price), qty > 0, prc > 0 {
                    try await vm.addPosition(
                        symbol: trimmedSymbol,
                        assetClass: assetClass,
                        dataSource: source,
                        quantity: qty,
                        price: prc
                    )
                } else {
                    try await vm.addHolding(
                        symbol: trimmedSymbol,
                        assetClass: assetClass,
                        dataSource: source
                    )
                }
                isSubmitting = false
                onSubmitted()
            } catch {
                // Keep the sheet open so the user can see what went wrong
                // (usually: server unreachable, bad symbol, network error).
                isSubmitting = false
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .semibold))
            Text(message)
                .font(.labelLg)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Color.red)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
