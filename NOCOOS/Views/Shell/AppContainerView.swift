import SwiftUI

struct AppContainerView: View {
    let app: NOCOAppID
    @EnvironmentObject private var router: NOCOOSRouter
    @State private var dragOffset: CGFloat = 0
    @State private var appear = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.4 + Double(min(dragOffset, 120)) / 400)
                .ignoresSafeArea()
                .onTapGesture { close() }

            VStack(spacing: 0) {
                grabber
                appHeader
                AppRegistry.view(for: app)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .background {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(Color(red: 0.06, green: 0.07, blue: 0.12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    }
                    .shadow(color: app.accent.opacity(0.25), radius: 30, y: 8)
                    .ignoresSafeArea(edges: .bottom)
            }
            .padding(.top, 48)
            .padding(.horizontal, 6)
            .offset(y: max(0, dragOffset))
            .scaleEffect(appear ? 1 : 0.9, anchor: .bottom)
            .opacity(appear ? 1 : 0)
            .safeAreaInset(edge: .bottom) {
                homeIndicator
            }
        }
        .onAppear {
            withAnimation(NOCOOSTheme.spring(response: 0.48, dampingFraction: 0.86)) {
                appear = true
            }
        }
    }

    private var grabber: some View {
        Capsule()
            .fill(Color.white.opacity(0.28))
            .frame(width: 40, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(dismissGesture)
    }

    private var appHeader: some View {
        HStack(spacing: 12) {
            Button(action: close) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.down")
                    Text("Home")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .nocoLiquidGlass(cornerRadius: 14)
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 8) {
                Circle()
                    .fill(app.accent)
                    .frame(width: 9, height: 9)
                    .shadow(color: app.accent.opacity(0.7), radius: 4)
                Text(app.displayName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
            }

            if app != .nocoAI {
                Button {
                    NOCOOSTheme.selectionHaptic()
                    router.open(.nocoAI)
                } label: {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background {
                            Circle().fill(NOCOOSTheme.aiGradient.opacity(0.85))
                        }
                        .overlay { RainbowRing(lineWidth: 1.5).frame(width: 36, height: 36) }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .gesture(dismissGesture)
    }

    private var homeIndicator: some View {
        Capsule()
            .fill(Color.white.opacity(0.35))
            .frame(width: 128, height: 5)
            .padding(.bottom, 8)
            .onTapGesture { close() }
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 90 || value.predictedEndTranslation.height > 160 {
                            close()
                        } else {
                            withAnimation(NOCOOSTheme.spring()) { dragOffset = 0 }
                        }
                    }
            )
    }

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onChanged { value in
                if value.translation.height > 0 {
                    dragOffset = value.translation.height * 0.85
                }
            }
            .onEnded { value in
                if value.translation.height > 110 || value.predictedEndTranslation.height > 180 {
                    close()
                } else {
                    withAnimation(NOCOOSTheme.spring()) { dragOffset = 0 }
                }
            }
    }

    private func close() {
        NOCOOSTheme.lightHaptic()
        withAnimation(NOCOOSTheme.softSpring()) {
            appear = false
            dragOffset = 160
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            router.closeApp()
        }
    }
}
