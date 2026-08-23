import SwiftUI

struct AppContainerView: View {
    let app: NOCOAppID
    @EnvironmentObject private var router: NOCOOSRouter

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { router.closeApp() }

            VStack(spacing: 0) {
                appHeader
                AppRegistry.view(for: app)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(red: 0.07, green: 0.08, blue: 0.14))
                    .ignoresSafeArea(edges: .bottom)
            )
            .padding(.top, 54)
            .padding(.horizontal, 8)
            .nocoSwipeUpHome()
        }
    }

    private var appHeader: some View {
        HStack {
            Button {
                router.closeApp()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.down")
                    Text("NOCO OS")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .nocoGlass(cornerRadius: 14)
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 8) {
                Circle()
                    .fill(app.accent)
                    .frame(width: 10, height: 10)
                Text(app.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
