import SwiftUI

struct AppStoreAppView: View {
    @EnvironmentObject private var router: NOCOOSRouter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                featured
                allApps
            }
            .padding(16)
        }
        .background(Color(red: 0.07, green: 0.08, blue: 0.14))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NOCO App Store")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text("Apps für dein NOCO OS")
                .foregroundStyle(NOCOOSTheme.textSecondary)
        }
    }

    private var featured: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Empfohlen")
                .font(.headline)
                .foregroundStyle(.white)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach([NOCOAppID.nocoAI, .games, .camera]) { app in
                        storeCard(app, large: true)
                    }
                }
            }
        }
    }

    private var allApps: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Alle Apps")
                .font(.headline)
                .foregroundStyle(.white)
            LazyVStack(spacing: 10) {
                ForEach(NOCOAppID.storeApps) { app in
                    storeRow(app)
                }
            }
        }
    }

    private func storeCard(_ app: NOCOAppID, large: Bool) -> some View {
        Button { router.open(app) } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: app.iconName)
                    .font(.system(size: large ? 32 : 24))
                    .foregroundStyle(.white)
                    .frame(width: large ? 56 : 44, height: large ? 56 : 44)
                    .background(app.accent.opacity(0.85), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                Text(app.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(app.storeDescription)
                    .font(.caption)
                    .foregroundStyle(NOCOOSTheme.textSecondary)
                    .lineLimit(2)
            }
            .padding(16)
            .frame(width: large ? 200 : 160, alignment: .leading)
            .nocoGlass(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }

    private func storeRow(_ app: NOCOAppID) -> some View {
        Button { router.open(app) } label: {
            HStack(spacing: 14) {
                Image(systemName: app.iconName)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(app.accent.opacity(0.85), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.displayName).foregroundStyle(.white).font(.headline)
                    Text(app.storeDescription).foregroundStyle(NOCOOSTheme.textSecondary).font(.caption)
                }
                Spacer()
                Text("Öffnen")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(NOCOOSTheme.accent)
            }
            .padding(12)
            .nocoGlass(cornerRadius: 16, opacity: 0.08)
        }
        .buttonStyle(.plain)
    }
}
