import SwiftUI

struct TimerAppView: View {
    @State private var seconds = 300
    @State private var remaining = 300
    @State private var running = false
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 24) {
            Text(timeString(remaining))
                .font(.system(size: 56, weight: .thin, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            Slider(value: Binding(
                get: { Double(seconds) },
                set: { if !running { seconds = Int($0); remaining = seconds } }
            ), in: 30...3600, step: 30)
            .tint(NOCOOSTheme.accent)
            .disabled(running)

            HStack(spacing: 16) {
                Button(running ? "Pause" : "Start") {
                    running ? pause() : start()
                }
                .buttonStyle(.borderedProminent)

                Button("Reset") {
                    pause()
                    remaining = seconds
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(red: 0.07, green: 0.08, blue: 0.14))
    }

    private func start() {
        running = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remaining > 0 {
                remaining -= 1
            } else {
                pause()
                NOCOOSTheme.mediumHaptic()
            }
        }
    }

    private func pause() {
        running = false
        timer?.invalidate()
        timer = nil
    }

    private func timeString(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }
}
