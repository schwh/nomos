import SwiftUI

// MARK: - Glass Card
// Implements the "Glass & Gradient Rule" from the design spec:
//   - Backdrop blur (heavy)
//   - Linear gradient: primary @ 12% → surface-tint @ 4%
//   - Ghost border: outline-variant @ 15% opacity
//   - Ambient glow blob (optional, for hero cards)
//   - Corner radius: xl (24px) for cards, md (12px) for compact

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 24
    var showGlow: Bool = false
    var padding: CGFloat = 20
    let content: () -> Content

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            content()
                .padding(padding)
                .background {
                    glassBackground
                }

            if showGlow {
                ambientGlowBlob
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.outlineVariant.opacity(0.15), lineWidth: 1)
        }
    }

    // Backdrop blur + primary gradient overlay
    private var glassBackground: some View {
        ZStack {
            // Dark base so blur has something rich to work with
            Color.surfaceContainerLow

            // Blur layer
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.6)

            // Primary glow gradient (the "liquid glass" effect)
            LinearGradient(
                colors: [
                    Color.primary.opacity(0.12),
                    Color.surfaceTint.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // Decorative glow blob — used on hero/balance cards
    private var ambientGlowBlob: some View {
        Ellipse()
            .fill(Color.primary.opacity(0.05))
            .frame(width: 180, height: 180)
            .blur(radius: 60)
            .offset(x: 40, y: 40)
            .allowsHitTesting(false)
    }
}

// MARK: - Surface Card (no blur — for list items and secondary content)
// Uses tonal layering only (surface-container-low on surface background).

struct SurfaceCard<Content: View>: View {
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 16
    let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(Color.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.outlineVariant.opacity(0.10), lineWidth: 1)
            }
    }
}

// MARK: - Grain Overlay
// 2% opacity noise texture over the entire screen.
// Uses a procedural CIFilter noise — no external asset needed.

struct GrainOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                // Draw seeded random noise at 2% opacity
                var rng = SystemRandomNumberGenerator()
                for x in stride(from: 0, to: size.width, by: 2) {
                    for y in stride(from: 0, to: size.height, by: 2) {
                        let brightness = Double.random(in: 0...1, using: &rng)
                        context.fill(
                            Path(CGRect(x: x, y: y, width: 2, height: 2)),
                            with: .color(Color.white.opacity(brightness * 0.02))
                        )
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .allowsHitTesting(false)
            .ignoresSafeArea()
        }
    }
}

// MARK: - Pulse Node
// Small real-time connectivity indicator (spec: "Pulse Node").

struct PulseNode: View {
    @State private var pulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.primaryFixed.opacity(0.25))
                .frame(width: 12, height: 12)
                .scaleEffect(pulsing ? 1.8 : 1.0)
                .opacity(pulsing ? 0 : 1)

            Circle()
                .fill(Color.primaryFixed)
                .frame(width: 4, height: 4)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                pulsing = true
            }
        }
    }
}

// MARK: - App background modifier
// Applies the surface base color + grain overlay to any screen.

struct AppBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.surface.ignoresSafeArea())
            .overlay(alignment: .topLeading) {
                GrainOverlay()
            }
    }
}

extension View {
    func appBackground() -> some View {
        modifier(AppBackgroundModifier())
    }
}
