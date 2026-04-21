import SwiftUI

// Compact glass card shown as an overlay, not a full-screen sheet.
// The parent (HoldingsView) drives the expand/collapse transition anchored
// to the + button, giving a macOS-tab-opening feel.
struct AddHoldingCard: View {
    @EnvironmentObject private var vm: PortfolioViewModel
    @EnvironmentObject private var theme: ThemeManager

    var onCancel: () -> Void
    var onSubmitted: () -> Void

    @State private var symbol = ""
    @State private var assetClass: AssetClass = .stock
    @State private var isSubmitting = false
    @FocusState private var symbolFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            symbolField
            assetClassPicker
            footerHint
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
        .onAppear { symbolFocused = true }
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

            TextField("", text: $symbol, prompt: Text("AAPL, BTC, EUR...").foregroundColor(Color.secondaryText))
                .focused($symbolFocused)
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
                            symbolFocused ? theme.current.accent.opacity(0.55)
                                          : Color.outlineVariant.opacity(0.15),
                            lineWidth: 1
                        )
                }
                .animation(.easeOut(duration: 0.15), value: symbolFocused)
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

    private var footerHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .semibold))
            Text("Data source auto-selected from \(DataSource.defaultFor(assetClass).displayName)")
                .font(.labelLg)
        }
        .foregroundStyle(Color.secondaryText)
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
                    Text(isSubmitting ? "Adding..." : "Add")
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

    // MARK: - Actions

    private var canSubmit: Bool {
        !symbol.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func submit() {
        guard canSubmit else { return }
        isSubmitting = true
        Task {
            await vm.addHolding(
                symbol: symbol.trimmingCharacters(in: .whitespaces).uppercased(),
                assetClass: assetClass,
                dataSource: DataSource.defaultFor(assetClass)
            )
            isSubmitting = false
            onSubmitted()
        }
    }
}
