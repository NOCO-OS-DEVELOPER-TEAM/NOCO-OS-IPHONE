import SwiftUI

enum NOCOOSTheme {
    static let accent = Color(red: 0.35, green: 0.55, blue: 1.0)
    static let accentGlow = Color(red: 0.45, green: 0.65, blue: 1.0)
    static let surface = Color.white.opacity(0.08)
    static let surfaceStrong = Color.white.opacity(0.14)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.72)
    static let danger = Color(red: 1.0, green: 0.35, blue: 0.35)

    static let homeGradient = LinearGradient(
        colors: [
            Color(red: 0.06, green: 0.08, blue: 0.18),
            Color(red: 0.10, green: 0.12, blue: 0.28),
            Color(red: 0.04, green: 0.06, blue: 0.14)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let aiGradient = LinearGradient(
        colors: [
            Color(red: 0.20, green: 0.35, blue: 0.95),
            Color(red: 0.45, green: 0.25, blue: 0.85),
            Color(red: 0.15, green: 0.55, blue: 0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func spring(response: Double = 0.42, dampingFraction: Double = 0.82) -> Animation {
        .spring(response: response, dampingFraction: dampingFraction)
    }

    static func lightHaptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func mediumHaptic() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func selectionHaptic() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 22
    var opacity: Double = 0.12

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(opacity), lineWidth: 1)
            )
    }
}

extension View {
    func nocoGlass(cornerRadius: CGFloat = 22, opacity: Double = 0.12) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius, opacity: opacity))
    }
}
