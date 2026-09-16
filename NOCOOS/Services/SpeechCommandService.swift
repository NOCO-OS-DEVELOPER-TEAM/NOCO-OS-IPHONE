import Foundation
import Speech
import AVFoundation

@MainActor
final class SpeechCommandService: ObservableObject {
    @Published var isListening = false
    @Published var transcript = ""
    @Published var authorizationDenied = false

    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var hasInstalledTap = false
    private var listenGeneration = 0

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func startListening(onFinal: @escaping (String) -> Void) async {
        guard !isListening else { return }
        let speechOK = await requestAuthorization()
        guard speechOK else {
            authorizationDenied = true
            return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            authorizationDenied = true
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        guard let recognizer, recognizer.isAvailable else {
            stopListening()
            return
        }

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            authorizationDenied = true
            stopListening()
            return
        }

        if hasInstalledTap {
            input.removeTap(onBus: 0)
            hasInstalledTap = false
        }
        // Capture local request — never touch MainActor state from the realtime audio tap.
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        hasInstalledTap = true

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            stopListening()
            return
        }

        let generation = listenGeneration
        isListening = true
        transcript = ""

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                Task { @MainActor in
                    guard generation == self.listenGeneration else { return }
                    self.transcript = result.bestTranscription.formattedString
                    if result.isFinal {
                        let text = self.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                        self.stopListening()
                        if !text.isEmpty {
                            onFinal(text)
                        }
                    }
                }
            }
            if error != nil {
                Task { @MainActor in
                    guard generation == self.listenGeneration else { return }
                    self.stopListening()
                }
            }
        }
    }

    func stopListening() {
        listenGeneration += 1
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if hasInstalledTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        isListening = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
