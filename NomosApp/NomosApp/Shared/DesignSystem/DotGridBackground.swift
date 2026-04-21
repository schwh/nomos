import SwiftUI

// Canvas-style dot grid with a radial size/opacity falloff.
// Dots are their biggest/brightest near the center and shrink + fade as
// they approach the corners, producing a soft "vignette" anchored to the
// content area. Inspired by Figma/FigJam/Whimsical dotted canvases.
struct DotGridBackground: View {
    var spacing: CGFloat = 24
    var maxDotSize: CGFloat = 1.8
    var tint: Color = .white

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let cx = size.width / 2
                let cy = size.height / 2
                let maxDist = sqrt(cx * cx + cy * cy)

                var y: CGFloat = spacing / 2
                while y < size.height {
                    var x: CGFloat = spacing / 2
                    while x < size.width {
                        let dx = x - cx
                        let dy = y - cy
                        let t = min(1, sqrt(dx * dx + dy * dy) / maxDist)

                        // Non-linear falloff: dots stay readable near center,
                        // drop off sharply toward edges.
                        let scale = max(0, 1 - pow(t, 1.35) * 0.88)
                        let alpha = 0.06 + (1 - t) * 0.36
                        let r = maxDotSize * scale

                        if r > 0.35 {
                            let rect = CGRect(x: x - r / 2, y: y - r / 2, width: r, height: r)
                            ctx.fill(Path(ellipseIn: rect),
                                     with: .color(tint.opacity(alpha)))
                        }
                        x += spacing
                    }
                    y += spacing
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}
