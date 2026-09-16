import SwiftUI

struct SwipeDownToSpotlightModifier: ViewModifier {
    @EnvironmentObject private var router: NOCOOSRouter
    @State private var dragY: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(y: dragY * 0.12)
            .simultaneousGesture(
                DragGesture(minimumDistance: 16, coordinateSpace: .global)
                    .onChanged { value in
                        guard router.activeApp == nil, !router.showSpotlight else { return }
                        // Prefer pulls starting in the upper third of the screen
                        if value.startLocation.y < 220, value.translation.height > 0 {
                            dragY = min(value.translation.height, 140)
                        }
                    }
                    .onEnded { value in
                        guard router.activeApp == nil, !router.showSpotlight else {
                            withAnimation(NOCOOSTheme.spring()) { dragY = 0 }
                            return
                        }
                        // Must start in upper area — otherwise home scrolling opens Spotlight.
                        if value.startLocation.y < 220,
                           value.translation.height > 55 || value.predictedEndTranslation.height > 100 {
                            router.openSpotlight()
                        }
                        withAnimation(NOCOOSTheme.spring()) { dragY = 0 }
                    }
            )
    }
}

struct SwipeUpToHomeModifier: ViewModifier {
    @EnvironmentObject private var router: NOCOOSRouter
    @State private var dragY: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(y: max(0, -dragY) * 0.08)
            .simultaneousGesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onChanged { value in
                        guard router.activeApp != nil else { return }
                        if value.translation.height < 0 {
                            dragY = max(value.translation.height, -120)
                        }
                    }
                    .onEnded { value in
                        guard router.activeApp != nil else { return }
                        if value.translation.height < -70 || value.predictedEndTranslation.height < -110 {
                            router.closeApp()
                        }
                        withAnimation(NOCOOSTheme.spring()) { dragY = 0 }
                    }
            )
    }
}

/// Long edge swipe from right → open NOCO AI (system brain).
struct EdgeSwipeAIModifier: ViewModifier {
    @EnvironmentObject private var router: NOCOOSRouter
    @State private var progress: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .trailing) {
                Color.clear
                    .frame(width: 18)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 12, coordinateSpace: .local)
                            .onChanged { value in
                                guard router.activeApp != .nocoAI else { return }
                                if value.translation.width < 0 {
                                    progress = min(1, -value.translation.width / 120)
                                }
                            }
                            .onEnded { value in
                                if -value.translation.width > 70 {
                                    NOCOOSTheme.mediumHaptic()
                                    router.open(.nocoAI)
                                }
                                withAnimation(NOCOOSTheme.spring()) { progress = 0 }
                            }
                    )
                    .overlay(alignment: .trailing) {
                        if progress > 0.05 {
                            Capsule()
                                .fill(NOCOOSTheme.rainbowLinear)
                                .frame(width: 4, height: 80 * progress)
                                .padding(.trailing, 4)
                                .nocoRainbowGlow(active: true, radius: 8)
                        }
                    }
            }
    }
}

extension View {
    func nocoSwipeDownSpotlight() -> some View {
        modifier(SwipeDownToSpotlightModifier())
    }

    func nocoSwipeUpHome() -> some View {
        modifier(SwipeUpToHomeModifier())
    }

    func nocoEdgeSwipeAI() -> some View {
        modifier(EdgeSwipeAIModifier())
    }
}
