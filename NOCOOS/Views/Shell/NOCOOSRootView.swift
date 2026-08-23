import SwiftUI

struct NOCOOSRootView: View {
    @EnvironmentObject private var router: NOCOOSRouter
    @EnvironmentObject private var connection: ConnectionStore

    var body: some View {
        ZStack {
            HomeScreenView()
                .blur(radius: router.activeApp == nil ? 0 : 8)
                .scaleEffect(router.activeApp == nil ? 1 : 0.96)
                .animation(NOCOOSTheme.spring(), value: router.activeApp)

            if let app = router.activeApp {
                AppContainerView(app: app)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.88, anchor: .center).combined(with: .opacity),
                        removal: .scale(scale: 0.94).combined(with: .opacity)
                    ))
                    .zIndex(2)
            }

            if router.showSpotlight {
                SpotlightView()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(3)
            }
        }
        .background(NOCOOSTheme.homeGradient.ignoresSafeArea())
        .task {
            await connection.refreshStatus()
        }
    }
}
