import SwiftUI

struct VideoAppView: View {
    @EnvironmentObject private var router: NOCOOSRouter

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.fill")
                .font(.system(size: 56))
                .foregroundStyle(NOCOOSTheme.accent)
            Text("Videoaufnahmen")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Video ist in der Kamera-App integriert.")
                .foregroundStyle(NOCOOSTheme.textSecondary)
            Button("Kamera öffnen (Video)") {
                router.closeApp()
                router.openCamera(mode: .video)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.07, green: 0.08, blue: 0.14))
    }
}
