import SwiftUI

struct AppIconTile: View {
    let app: NOCOAppID
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            NOCOOSTheme.lightHaptic()
            withAnimation(NOCOOSTheme.spring(response: 0.28, dampingFraction: 0.62)) {
                pressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                pressed = false
                action()
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [app.accent.opacity(0.95), app.accent.opacity(0.55)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                        )
                        .shadow(color: app.accent.opacity(0.35), radius: pressed ? 4 : 12, y: pressed ? 2 : 8)

                    Image(systemName: app.iconName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse, options: app == .nocoAI ? .repeating : .nonRepeating)
                }
                .scaleEffect(pressed ? 0.9 : 1)

                Text(app.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(app.displayName)
    }
}
