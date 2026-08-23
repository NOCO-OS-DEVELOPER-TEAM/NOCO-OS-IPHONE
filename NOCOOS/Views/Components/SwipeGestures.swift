import SwiftUI

struct SwipeDownToSpotlightModifier: ViewModifier {
    @EnvironmentObject private var router: NOCOOSRouter
    @State private var dragY: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(y: dragY * 0.08)
            .simultaneousGesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .global)
                    .onChanged { value in
                        guard router.activeApp == nil, !router.showSpotlight else { return }
                        if value.translation.height > 0 {
                            dragY = min(value.translation.height, 120)
                        }
                    }
                    .onEnded { value in
                        guard router.activeApp == nil else { return }
                        if value.translation.height > 60 {
                            router.openSpotlight()
                        }
                        withAnimation(NOCOOSTheme.spring()) {
                            dragY = 0
                        }
                    }
            )
    }
}

struct SwipeUpToHomeModifier: ViewModifier {
    @EnvironmentObject private var router: NOCOOSRouter
    @State private var dragY: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(y: dragY * 0.06)
            .simultaneousGesture(
                DragGesture(minimumDistance: 24, coordinateSpace: .local)
                    .onChanged { value in
                        guard router.activeApp != nil else { return }
                        if value.translation.height < 0 {
                            dragY = max(value.translation.height, -100)
                        }
                    }
                    .onEnded { value in
                        guard router.activeApp != nil else { return }
                        if value.translation.height < -80 || value.predictedEndTranslation.height < -120 {
                            router.closeApp()
                        }
                        withAnimation(NOCOOSTheme.spring()) {
                            dragY = 0
                        }
                    }
            )
    }
}

extension View {
    func nocoSwipeDownSpotlight() -> some View {
        modifier(SwipeDownToSpotlightModifier())
    }

    func nocoSwipeUpHome() -> some View {
        modifier(SwipeUpToHomeModifier())
    }
}
