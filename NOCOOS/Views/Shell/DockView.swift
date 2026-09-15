import SwiftUI

struct DockView: View {
    @EnvironmentObject private var router: NOCOOSRouter

    var body: some View {
        HStack(spacing: 18) {
            ForEach(NOCOAppID.dockApps) { app in
                if app == .nocoAI {
                    NOCOAICoreOrb(size: 54, pulsing: true) {
                        router.open(.nocoAI)
                    }
                } else {
                    AppIconTile(app: app, compact: true) {
                        router.open(app)
                    }
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .nocoLiquidGlass(cornerRadius: 34, rainbow: false)
        .nocoRainbowGlow(active: router.activeApp == nil, radius: 10)
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }
}
