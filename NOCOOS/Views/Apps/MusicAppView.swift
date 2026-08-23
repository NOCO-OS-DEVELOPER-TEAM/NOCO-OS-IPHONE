import SwiftUI

struct MusicAppView: View {
    @State private var playing = false
    @State private var track = 0
    private let tracks = ["NOCO Ambient", "Focus Flow", "System Pulse"]

    var body: some View {
        VStack(spacing: 28) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(NOCOOSTheme.aiGradient)
                .frame(height: 220)
                .overlay {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 64))
                        .foregroundStyle(.white.opacity(0.9))
                }

            Text(tracks[track])
                .font(.title2.bold())
                .foregroundStyle(.white)

            HStack(spacing: 32) {
                Button { track = max(0, track - 1) } label: {
                    Image(systemName: "backward.fill").font(.title)
                }
                Button {
                    playing.toggle()
                    NOCOOSTheme.mediumHaptic()
                } label: {
                    Image(systemName: playing ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                }
                Button { track = min(tracks.count - 1, track + 1) } label: {
                    Image(systemName: "forward.fill").font(.title)
                }
            }
            .foregroundStyle(.white)

            Text("NOCO OS Musik — Demo-Wiedergabe")
                .font(.caption)
                .foregroundStyle(NOCOOSTheme.textSecondary)
        }
        .padding()
        .background(Color(red: 0.07, green: 0.08, blue: 0.14))
    }
}
