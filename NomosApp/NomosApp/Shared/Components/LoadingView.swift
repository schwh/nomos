import SwiftUI

struct LoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
