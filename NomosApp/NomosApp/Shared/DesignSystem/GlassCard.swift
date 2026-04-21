import SwiftUI

// MARK: - Glass Card
// Implements the "Glass & Gradient Rule" from the design spec:
//   - Backdrop blur (heavy)
//   - Linear gradient: primary @ 12% → surface-tint @ 4%
//   - Ghost border: outline-variant @ 15% opacity
//   - Ambient glow blob (optional, for hero cards)
//   - Corner radius: xl (24px) for cards, md (12px) for compact

struct GlassCard<Content: View>: View {
    @EnvironmentObject private var theme: ThemeManager

    var cornerRadius: CGFloat = 22
    var showGlow: Bool = false
    var padding: CGFloat = 20
    let content: () -> Content

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            content()
                .padding(padding)
                .background { glassBackground }

            if showGlow {
                ambientGlowBlob
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            // Sharper double-stroke: crisp outer edge + subtle inner sheen
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.14),
                            Color.white.opacity(0.02),
                            theme.current.accent.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    // Liquid-glass base: dark tonal floor → ultra-thin material → accent
    // gradient glaze → specular highlight stroke. Stacks build depth.
    private var glassBackground: some View {
        ZStack {
            Color.surfaceContainerLow

            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.55)

            LinearGradient(
                colors: [
                    theme.current.accent.opacity(0.14),
                    theme.current.accent.opacity(0.02),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Specular highlight along top edge
            LinearGradient(
                colors: [Color.white.opacity(0.08), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .blendMode(.screen)
        }
    }

    private var ambientGlowBlob: some View {
        Ellipse()
            .fill(theme.current.accent.opacity(0.10))
            .frame(width: 200, height: 200)
            .blur(radius: 70)
            .offset(x: 50, y: 50)
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
// Surface base color → optional theme tint wash → dot grid canvas overlay.
// The dot grid reads as the "canvas" and sits behind all content.

struct AppBackgroundModifier: ViewModifier {
    @EnvironmentObject private var theme: ThemeManager

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    Color.surface
                    theme.current.backgroundTint
                    DotGridBackground(tint: theme.current.dotTint)
                }
                .ignoresSafeArea()
            }
    }
}

extension View {
    func appBackground() -> some View {
        modifier(AppBackgroundModifier())
    }
}
