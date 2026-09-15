import SwiftUI

struct NOCOOSRootView: View {
    @EnvironmentObject private var router: NOCOOSRouter
    @EnvironmentObject private var connection: ConnectionStore
    @State private var showBoot = true
    @State private var homeParallax: CGFloat = 0

    var body: some View {
        ZStack {
            NOCOAtmosphere()

            // HOME
            VStack(spacing: 0) {
                HomeScreenView()
                    .offset(y: homeParallax)
                DockView()
                    .opacity(router.activeApp == nil && !router.showSpotlight ? 1 : 0)
                    .offset(y: router.activeApp == nil ? 0 : 40)
                    .allowsHitTesting(router.activeApp == nil && !router.showSpotlight)
            }
            .scaleEffect(router.activeApp == nil ? (router.showSpotlight ? 0.97 : 1) : 0.92)
            .blur(radius: router.activeApp == nil ? (router.showSpotlight ? 6 : 0) : 10)
            .opacity(router.activeApp == nil ? 1 : 0.55)
            .animation(NOCOOSTheme.softSpring(), value: router.activeApp)
            .animation(NOCOOSTheme.softSpring(), value: router.showSpotlight)
            .nocoSwipeDownSpotlight()
            .nocoEdgeSwipeAI()

            // APP STAGE
            if let app = router.activeApp {
                AppContainerView(app: app)
                    .transition(
                        .asymmetric(
                            insertion: .modifier(
                                active: AppLaunchTransition(progress: 0),
                                identity: AppLaunchTransition(progress: 1)
                            ),
                            removal: .opacity.combined(with: .scale(scale: 0.94))
                        )
                    )
                    .zIndex(2)
            }

            // SPOTLIGHT
            if router.showSpotlight {
                SpotlightView()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(3)
            }

            // Floating AI when in an app (system brain always reachable)
            if router.activeApp != nil, router.activeApp != .nocoAI, !router.showSpotlight {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        NOCOAICoreOrb(size: 52, pulsing: true) {
                            router.open(.nocoAI)
                        }
                        .padding(.trailing, 22)
                        .padding(.bottom, 36)
                    }
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(4)
            }

            if showBoot {
                BootSplashView(isVisible: $showBoot)
                    .zIndex(10)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await connection.refreshStatus()
        }
    }
}

private struct AppLaunchTransition: ViewModifier {
    var progress: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(0.82 + 0.18 * progress, anchor: .bottom)
            .opacity(Double(progress))
            .offset(y: (1 - progress) * 40)
    }
}
