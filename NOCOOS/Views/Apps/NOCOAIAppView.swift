import SwiftUI

struct NOCOAIAppView: View {
    @EnvironmentObject private var connection: ConnectionStore
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var router: NOCOOSRouter
    @EnvironmentObject private var aiService: AIService

    @StateObject private var speech = SpeechCommandService()
    @State private var input = ""
    @State private var glowPhase = false

    var body: some View {
        VStack(spacing: 0) {
            aiHeader
            messageList
            inputBar
        }
        .onReceive(NotificationCenter.default.publisher(for: .nocoOSSpotlightAI)) { note in
            if let prompt = note.object as? String {
                input = prompt
                Task { await send() }
            }
        }
    }

    private var aiHeader: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(NOCOOSTheme.aiGradient)
                    .frame(width: 46, height: 46)
                    .shadow(color: NOCOOSTheme.accent.opacity(glowPhase ? 0.6 : 0.2), radius: glowPhase ? 18 : 8)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowPhase)
                Image(systemName: "sparkles")
                    .foregroundStyle(.white)
            }
            .onAppear { glowPhase = true }

            VStack(alignment: .leading, spacing: 2) {
                Text("NOCO AI")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(connection.isOnline ? "Mit Windows-PC verbunden" : "Offline · Einstellungen prüfen")
                    .font(.caption)
                    .foregroundStyle(NOCOOSTheme.textSecondary)
            }
            Spacer()
            Button {
                Task {
                    if speech.isListening {
                        speech.stopListening()
                    } else {
                        await speech.startListening { text in
                            input = text
                            Task { await send() }
                        }
                    }
                }
            } label: {
                Image(systemName: speech.isListening ? "waveform.circle.fill" : "mic.fill")
                    .font(.title3)
                    .foregroundStyle(speech.isListening ? NOCOOSTheme.accent : .white.opacity(0.85))
                    .symbolEffect(.variableColor.iterative, isActive: speech.isListening)
            }
            .buttonStyle(.plain)
            .disabled(!settings.voiceEnabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(aiService.messages) { message in
                        messageBubble(message)
                            .id(message.id)
                    }
                }
                .padding(16)
            }
            .onChange(of: aiService.messages.count) { _, _ in
                if let last = aiService.messages.last?.id {
                    withAnimation(NOCOOSTheme.spring()) {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.text)
                .font(.body)
                .foregroundStyle(message.role == .user ? Color.black : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(message.role == .user ? Color.white : Color.white.opacity(0.12))
                )
                .opacity(message.isProcessing ? 0.7 : 1)
                .overlay {
                    if message.isProcessing {
                        ProgressView()
                            .tint(.white)
                    }
                }
            if message.role != .user { Spacer(minLength: 40) }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Frag NOCO AI …", text: $input, axis: .vertical)
                .lineLimit(1...4)
                .padding(12)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .foregroundStyle(.white)
            Button {
                Task { await send() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : NOCOOSTheme.accent)
            }
            .buttonStyle(.plain)
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiService.isProcessing)
        }
        .padding(14)
        .background(Color.black.opacity(0.25))
    }

    private func send() async {
        let text = input
        input = ""
        NOCOOSTheme.lightHaptic()
        _ = await aiService.send(text, router: router)
    }
}
