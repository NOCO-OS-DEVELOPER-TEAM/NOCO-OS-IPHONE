import SwiftUI

struct BootSplashView: View {
    @Binding var isVisible: Bool
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var ringSpin = false
    @State private var titleOpacity: Double = 0
    @State private var dismissProgress: CGFloat = 0

    var body: some View {
        ZStack {
            NOCOAtmosphere()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(NOCOOSTheme.rainbowLinear.opacity(0.35))
                        .frame(width: 140, height: 140)
                        .blur(radius: 28)
                        .scaleEffect(ringSpin ? 1.15 : 0.9)

                    RainbowRing(lineWidth: 3)
                        .frame(width: 108, height: 108)
                        .rotationEffect(.degrees(ringSpin ? 360 : 0))

                    Image(systemName: "sparkles")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(.white)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                VStack(spacing: 8) {
                    Text("NOCO OS")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Dein System · Angetrieben von NOCO AI")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(NOCOOSTheme.textSecondary)
                }
                .opacity(titleOpacity)
            }
        }
        .opacity(1 - Double(dismissProgress))
        .scaleEffect(1 + dismissProgress * 0.06)
        .ignoresSafeArea()
        .onAppear { runBoot() }
        .allowsHitTesting(isVisible)
    }

    private func runBoot() {
        NOCOOSTheme.mediumHaptic()
        withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
            logoScale = 1
            logoOpacity = 1
        }
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false)) {
            ringSpin = true
        }
        withAnimation(.easeOut(duration: 0.55).delay(0.25)) {
            titleOpacity = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.65) {
            withAnimation(.easeInOut(duration: 0.55)) {
                dismissProgress = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                isVisible = false
                NOCOOSTheme.successHaptic()
            }
        }
    }
}
