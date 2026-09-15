import SwiftUI

struct HomeScreenView: View {
    @EnvironmentObject private var router: NOCOOSRouter
    @EnvironmentObject private var connection: ConnectionStore
    @EnvironmentObject private var ai: AIService
    @State private var now = Date()
    @State private var appear = false

    private let timer = Timer.publish(every: 20, on: .main, in: .common).autoconnect()

    private var pageApps: [NOCOAppID] {
        NOCOAppID.homeScreenApps.filter { !NOCOAppID.dockApps.contains($0) }
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                statusStrip
                    .padding(.horizontal, 22)
                    .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        clockHero
                        aiSystemCard
                        appGrid
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 16)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onReceive(timer) { now = $0 }
        .onAppear {
            now = Date()
            withAnimation(NOCOOSTheme.softSpring()) { appear = true }
        }
    }

    private var statusStrip: some View {
        HStack {
            Text(now, format: .dateTime.hour().minute())
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .monospacedDigit()
            Spacer()
            HStack(spacing: 8) {
                Circle()
                    .fill(connection.isOnline ? Color(red: 0.35, green: 0.95, blue: 0.55) : Color.orange)
                    .frame(width: 7, height: 7)
                    .shadow(color: connection.isOnline ? .green.opacity(0.6) : .clear, radius: 4)
                Image(systemName: "wifi")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
                Image(systemName: "battery.100")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
    }

    private var clockHero: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(now, format: .dateTime.hour().minute())
                .font(.system(size: 72, weight: .ultraLight, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .shadow(color: NOCOOSTheme.accent.opacity(0.25), radius: 20)
            Text(now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.title3.weight(.medium))
                .foregroundStyle(NOCOOSTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var aiSystemCard: some View {
        Button {
            NOCOOSTheme.mediumHaptic()
            router.open(.nocoAI)
        } label: {
            HStack(spacing: 14) {
                NOCOAICoreOrb(size: 48, pulsing: true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("NOCO AI")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(connection.isOnline ? "System bereit · Frag mich etwas" : "Offline · Server in Einstellungen")
                        .font(.caption)
                        .foregroundStyle(NOCOOSTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(16)
            .nocoLiquidGlass(cornerRadius: 26, rainbow: true)
            .nocoRainbowGlow(active: true, radius: 14)
        }
        .buttonStyle(OSPressStyle())
    }

    private var appGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 18), count: 4)
        return LazyVGrid(columns: columns, spacing: 22) {
            ForEach(Array(pageApps.enumerated()), id: \.element.id) { index, app in
                AppIconTile(app: app) {
                    router.open(app)
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 12)
                .animation(NOCOOSTheme.spring().delay(Double(index) * 0.03), value: appear)
            }
        }
        .padding(.top, 4)
    }
}

struct OSPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(NOCOOSTheme.snappy(), value: configuration.isPressed)
    }
}
