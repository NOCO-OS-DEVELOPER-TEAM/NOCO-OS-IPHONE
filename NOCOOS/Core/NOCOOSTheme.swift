import SwiftUI
import UIKit

/// NOCO OS visual language — Apple Liquid Glass inspired, with NOCO AI rainbow identity.
enum NOCOOSTheme {
    static let accent = Color(red: 0.42, green: 0.62, blue: 1.0)
    static let accentGlow = Color(red: 0.55, green: 0.75, blue: 1.0)
    static let surface = Color.white.opacity(0.08)
    static let surfaceStrong = Color.white.opacity(0.14)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.68)
    static let danger = Color(red: 1.0, green: 0.38, blue: 0.42)

    static let rainbow: [Color] = [
        Color(red: 1.0, green: 0.38, blue: 0.58),
        Color(red: 1.0, green: 0.72, blue: 0.28),
        Color(red: 0.35, green: 0.95, blue: 0.58),
        Color(red: 0.28, green: 0.75, blue: 1.0),
        Color(red: 0.62, green: 0.45, blue: 1.0),
        Color(red: 1.0, green: 0.38, blue: 0.58)
    ]

    static var rainbowGradient: AngularGradient {
        AngularGradient(colors: rainbow, center: .center)
    }

    static var rainbowLinear: LinearGradient {
        LinearGradient(colors: rainbow, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let homeGradient = LinearGradient(
        colors: [
            Color(red: 0.04, green: 0.06, blue: 0.14),
            Color(red: 0.08, green: 0.10, blue: 0.22),
            Color(red: 0.03, green: 0.05, blue: 0.12)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let aiGradient = LinearGradient(
        colors: [
            Color(red: 0.35, green: 0.55, blue: 1.0),
            Color(red: 0.62, green: 0.35, blue: 0.95),
            Color(red: 0.25, green: 0.85, blue: 0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func spring(response: Double = 0.42, dampingFraction: Double = 0.84) -> Animation {
        .spring(response: response, dampingFraction: dampingFraction)
    }

    static func softSpring() -> Animation {
        .spring(response: 0.52, dampingFraction: 0.88)
    }

    static func snappy() -> Animation {
        .spring(response: 0.32, dampingFraction: 0.78)
    }

    static func lightHaptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
    }

    static func mediumHaptic() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func selectionHaptic() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func successHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Atmosphere

struct NOCOAtmosphere: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            NOCOOSTheme.homeGradient

            Circle()
                .fill(Color(red: 0.25, green: 0.45, blue: 1.0).opacity(0.28))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: -110 + phase * 18, y: -220)
                .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: phase)

            Circle()
                .fill(Color(red: 0.65, green: 0.35, blue: 1.0).opacity(0.22))
                .frame(width: 280, height: 280)
                .blur(radius: 100)
                .offset(x: 130 - phase * 12, y: 180)
                .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: phase)

            Circle()
                .fill(Color(red: 0.2, green: 0.9, blue: 0.75).opacity(0.12))
                .frame(width: 200, height: 200)
                .blur(radius: 70)
                .offset(x: 40, y: -40 + phase * 20)

            // Fine mesh highlight
            LinearGradient(
                colors: [
                    Color.white.opacity(0.06),
                    .clear,
                    Color.white.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
        .onAppear { phase = 1 }
        .allowsHitTesting(false)
    }
}

// MARK: - Liquid Glass

struct LiquidGlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 24
    var intensity: Double = 1.0
    var rainbowEdge: Bool = false

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.14 * intensity),
                                        Color.white.opacity(0.03 * intensity)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                rainbowEdge
                                ? AnyShapeStyle(NOCOOSTheme.rainbowLinear.opacity(0.55))
                                : AnyShapeStyle(Color.white.opacity(0.18 * intensity)),
                                lineWidth: rainbowEdge ? 1.2 : 1
                            )
                    }
                    .shadow(color: Color.black.opacity(0.28), radius: 18, y: 10)
            }
    }
}

struct RainbowGlowModifier: ViewModifier {
    var active: Bool = true
    var radius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .shadow(color: NOCOOSTheme.rainbow[0].opacity(active ? 0.35 : 0), radius: radius * 0.4)
            .shadow(color: NOCOOSTheme.rainbow[3].opacity(active ? 0.35 : 0), radius: radius * 0.55)
            .shadow(color: NOCOOSTheme.rainbow[4].opacity(active ? 0.28 : 0), radius: radius * 0.7)
    }
}

extension View {
    func nocoGlass(cornerRadius: CGFloat = 22, opacity: Double = 0.12) -> some View {
        modifier(LiquidGlassBackground(cornerRadius: cornerRadius, intensity: opacity / 0.12, rainbowEdge: false))
    }

    func nocoLiquidGlass(cornerRadius: CGFloat = 24, rainbow: Bool = false) -> some View {
        modifier(LiquidGlassBackground(cornerRadius: cornerRadius, intensity: 1.0, rainbowEdge: rainbow))
    }

    func nocoRainbowGlow(active: Bool = true, radius: CGFloat = 16) -> some View {
        modifier(RainbowGlowModifier(active: active, radius: radius))
    }
}

// MARK: - Rainbow ring / AI core

struct RainbowRing: View {
    var lineWidth: CGFloat = 2.5
    @State private var spin: Double = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let angle = (t.truncatingRemainder(dividingBy: 4.5) / 4.5) * 360
            Circle()
                .stroke(
                    AngularGradient(colors: NOCOOSTheme.rainbow, center: .center, angle: .degrees(angle)),
                    lineWidth: lineWidth
                )
                .blur(radius: 0.2)
        }
    }
}

struct NOCOAICoreOrb: View {
    var size: CGFloat = 56
    var pulsing: Bool = true
    var action: (() -> Void)?

    @State private var pulse = false

    var body: some View {
        Button {
            NOCOOSTheme.mediumHaptic()
            action?()
        } label: {
            ZStack {
                Circle()
                    .fill(NOCOOSTheme.rainbowLinear.opacity(0.55))
                    .frame(width: size + 18, height: size + 18)
                    .blur(radius: 14)
                    .scaleEffect(pulse && pulsing ? 1.12 : 0.95)
                    .opacity(0.85)

                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: size, height: size)

                Circle()
                    .fill(NOCOOSTheme.aiGradient.opacity(0.85))
                    .frame(width: size - 6, height: size - 6)

                RainbowRing(lineWidth: 2.2)
                    .frame(width: size + 4, height: size + 4)

                Image(systemName: "sparkles")
                    .font(.system(size: size * 0.34, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, options: pulsing ? .repeating : .nonRepeating)
            }
            .nocoRainbowGlow(active: true, radius: 20)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .accessibilityLabel("NOCO AI")
    }
}
