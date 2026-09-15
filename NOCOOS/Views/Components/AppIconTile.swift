import SwiftUI

struct AppIconTile: View {
    let app: NOCOAppID
    var compact: Bool = false
    let action: () -> Void

    @State private var pressed = false

    private var iconSize: CGFloat { compact ? 54 : 64 }

    var body: some View {
        Button {
            NOCOOSTheme.lightHaptic()
            withAnimation(NOCOOSTheme.snappy()) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(NOCOOSTheme.spring(response: 0.36, dampingFraction: 0.7)) {
                    pressed = false
                }
                action()
            }
        } label: {
            VStack(spacing: compact ? 0 : 8) {
                ZStack {
                    // Soft glow blob
                    RoundedRectangle(cornerRadius: iconSize * 0.28, style: .continuous)
                        .fill(app.accent.opacity(0.45))
                        .frame(width: iconSize, height: iconSize)
                        .blur(radius: pressed ? 4 : 12)
                        .opacity(pressed ? 0.5 : 0.85)

                    RoundedRectangle(cornerRadius: iconSize * 0.28, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: iconSize, height: iconSize)

                    RoundedRectangle(cornerRadius: iconSize * 0.28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    app.accent.opacity(0.95),
                                    app.accent.opacity(0.55),
                                    Color.white.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: iconSize, height: iconSize)
                        .overlay {
                            RoundedRectangle(cornerRadius: iconSize * 0.28, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                        }
                        .overlay(alignment: .top) {
                            // Liquid glass highlight
                            Capsule()
                                .fill(Color.white.opacity(0.35))
                                .frame(width: iconSize * 0.45, height: 3)
                                .padding(.top, 7)
                                .blur(radius: 0.5)
                        }

                    Image(systemName: app.iconName)
                        .font(.system(size: iconSize * 0.38, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                        .symbolEffect(.bounce, value: pressed)
                }
                .scaleEffect(pressed ? 0.88 : 1)
                .rotation3DEffect(.degrees(pressed ? 4 : 0), axis: (x: 1, y: 0, z: 0))

                if !compact {
                    Text(app.displayName)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(app.displayName)
    }
}
