import SwiftUI

struct HomeScreenView: View {
    @EnvironmentObject private var router: NOCOOSRouter
    @EnvironmentObject private var connection: ConnectionStore
    @State private var now = Date()

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    clockWidget
                    appGrid(width: geo.size.width)
                    statusBar
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
        }
        .onReceive(timer) { now = $0 }
        .onAppear { now = Date() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("NOCO OS")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(NOCOOSTheme.textPrimary)
                Text("Dein persönliches System")
                    .font(.subheadline)
                    .foregroundStyle(NOCOOSTheme.textSecondary)
            }
            Spacer()
            Button {
                router.openSpotlight()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .nocoGlass(cornerRadius: 14)
            }
            .buttonStyle(.plain)
        }
    }

    private var clockWidget: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(now, format: .dateTime.hour().minute())
                    .font(.system(size: 54, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                Text(now, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.headline)
                    .foregroundStyle(NOCOOSTheme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(connection.isOnline ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(connection.statusMessage)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(NOCOOSTheme.textSecondary)
                }
                Label("NOCO AI bereit", systemImage: "sparkles")
                    .font(.caption)
                    .foregroundStyle(NOCOOSTheme.accentGlow)
            }
        }
        .padding(20)
        .nocoGlass(cornerRadius: 26)
    }

    private func appGrid(width: CGFloat) -> some View {
        let columns = [GridItem(.adaptive(minimum: 78), spacing: 22)]
        return LazyVGrid(columns: columns, spacing: 26) {
            ForEach(NOCOAppID.homeScreenApps) { app in
                AppIconTile(app: app) {
                    router.open(app)
                }
            }
        }
        .padding(.top, 4)
    }

    private var statusBar: some View {
        HStack {
            Image(systemName: "hand.tap.fill")
                .foregroundStyle(NOCOOSTheme.textSecondary)
            Text("Nach unten wischen für Spotlight · Halte NOCO AI für Sprache")
                .font(.caption)
                .foregroundStyle(NOCOOSTheme.textSecondary)
        }
        .padding(.top, 8)
    }
}
