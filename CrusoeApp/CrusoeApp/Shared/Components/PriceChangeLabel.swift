import SwiftUI

enum PriceChangeLabelStyle {
    case small, large
}

struct PriceChangeLabel: View {
    let change: Double
    let percent: Double
    var style: PriceChangeLabelStyle = .small

    private var isPositive: Bool { change >= 0 }
    private var color: Color { isPositive ? Color.gainGreen : Color.lossRed }
    private var arrow: String { isPositive ? "arrow.up" : "arrow.down" }

    private var font: Font { style == .large ? .labelLg : .labelMd }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: arrow)
                .font(font.weight(.semibold))
            Text(String(format: "%.2f%%", abs(percent)))
                .font(font.weight(.semibold))
            if style == .large {
                Text("(\(abs(change).formatted(.currency(code: "USD"))))")
                    .font(.labelMd)
                    .foregroundStyle(color.opacity(0.75))
            }
        }
        .foregroundStyle(color)
    }
}
