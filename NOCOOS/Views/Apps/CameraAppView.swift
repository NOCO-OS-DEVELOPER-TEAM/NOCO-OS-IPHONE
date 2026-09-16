import SwiftUI
import AVFoundation
import Photos
import AVKit

enum CameraMode: String, CaseIterable {
    case photo = "Foto"
    case video = "Video"
}

struct CameraAppView: View {
    @EnvironmentObject private var connection: ConnectionStore
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var router: NOCOOSRouter
    @EnvironmentObject private var ai: AIService
    @EnvironmentObject private var bridge: SystemBridge

    @StateObject private var model = CameraModel()
    @State private var mode: CameraMode = .photo
    @State private var analysisResult = ""
    @State private var showAnalysis = false
    @State private var isAnalyzing = false
    @State private var showPreview = false

    var body: some View {
        VStack(spacing: 0) {
            modePicker

            ZStack {
                if model.permissionDenied {
                    ContentUnavailableView(
                        "Kamera nicht erlaubt",
                        systemImage: "camera.fill",
                        description: Text("Bitte Kamera-Zugriff in den iOS-Einstellungen erlauben.")
                    )
                } else if showPreview, let image = model.lastCapture {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .transition(.opacity)
                } else if showPreview, let url = model.lastVideoURL {
                    VideoPreviewView(url: url)
                        .transition(.opacity)
                } else {
                    CameraPreview(session: model.session)
                        .transition(.opacity)
                }

                if model.isRecording {
                    VStack {
                        HStack {
                            Circle().fill(.red).frame(width: 10, height: 10)
                            Text(model.recordingDuration.formatted(.number.precision(.fractionLength(0))) + " s")
                                .font(.caption.monospaced().weight(.bold))
                                .foregroundStyle(.white)
                        }
                        .padding(8)
                        .nocoGlass(cornerRadius: 10)
                        .padding(.top, 12)
                        Spacer()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(12)
            .frame(maxHeight: .infinity)

            controls
        }
        .onAppear {
            mode = router.cameraLaunchMode == .video ? .video : .photo
            model.configure()
        }
        .onDisappear { model.stop() }
        .onChange(of: mode) { _, _ in
            showPreview = false
            model.lastCapture = nil
            model.lastVideoURL = nil
        }
        .alert("NOCO AI", isPresented: $showAnalysis) {
            Button("Als Notiz speichern") {
                bridge.createNoteFromText(analysisResult)
                router.closeApp()
                router.open(.notes)
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(analysisResult)
        }
    }

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(CameraMode.allCases, id: \.self) { item in
                Button {
                    withAnimation(NOCOOSTheme.spring(response: 0.32)) { mode = item }
                    NOCOOSTheme.selectionHaptic()
                } label: {
                    Text(item.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(mode == item ? .black : .white.opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(mode == item ? Color.white : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.08), in: Capsule())
        .padding(.top, 8)
    }

    private var controls: some View {
        HStack(spacing: 28) {
            Button {
                showPreview = false
                model.lastCapture = nil
                model.lastVideoURL = nil
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
            }
            .foregroundStyle(.white)
            .disabled(!showPreview)

            Button {
                guard model.isReady else { return }
                if mode == .photo {
                    model.capturePhoto()
                    showPreview = true
                } else {
                    if model.isRecording {
                        model.stopRecording()
                        showPreview = true
                    } else {
                        model.startRecording()
                    }
                }
                NOCOOSTheme.mediumHaptic()
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 4)
                        .frame(width: 72, height: 72)
                    if mode == .video && model.isRecording {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.red)
                            .frame(width: 28, height: 28)
                    } else {
                        Circle()
                            .fill(mode == .video ? Color.red : Color.white)
                            .frame(width: 58, height: 58)
                            .opacity(model.isReady ? 1 : 0.4)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(!model.isReady && !(mode == .video && model.isRecording))

            Button {
                Task { await analyzeCapture() }
            } label: {
                if isAnalyzing {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "sparkles")
                        .font(.title2)
                }
            }
            .foregroundStyle(NOCOOSTheme.accentGlow)
            .disabled(!showPreview || isAnalyzing || ai.isProcessing)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.35))
    }

    private func analyzeCapture() async {
        guard !isAnalyzing else { return }
        isAnalyzing = true
        defer { isAnalyzing = false }

        if let image = model.lastCapture {
            bridge.registerCapture(image)
            model.saveToPhotos(image)
        }

        guard connection.isPaired else {
            analysisResult = "Für KI-Analyse bitte NOCO AI Server in Einstellungen verbinden."
            showAnalysis = true
            return
        }

        let context = model.lastCapture != nil
            ? "Der Nutzer hat ein Foto in NOCO OS aufgenommen."
            : "Der Nutzer hat ein Video in NOCO OS aufgenommen."

        if let reply = await ai.analyzeImageDescription(context) {
            analysisResult = reply
            showAnalysis = true
            settings.log("Camera AI analysis")
        }
    }
}

@MainActor
final class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    @Published var lastCapture: UIImage?
    @Published var lastVideoURL: URL?
    @Published var permissionDenied = false
    @Published var isRecording = false
    @Published var recordingDuration: Double = 0
    @Published var isReady = false

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "de.noco.nocoos.camera.session")
    private var isConfigured = false
    private var sessionGeneration = 0
    private var recordingTimer: Timer?

    func configure() {
        let generation = sessionGeneration
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startOrReuseSession(generation: generation)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    guard let self else { return }
                    if granted {
                        self.startOrReuseSession(generation: generation)
                    } else {
                        self.permissionDenied = true
                    }
                }
            }
        default:
            permissionDenied = true
        }
    }

    private func startOrReuseSession(generation: Int) {
        if isConfigured {
            sessionQueue.async { [weak self] in
                guard let self else { return }
                guard generation == self.sessionGeneration else { return }
                if !self.session.isRunning {
                    self.session.startRunning()
                }
                Task { @MainActor in
                    guard generation == self.sessionGeneration else { return }
                    self.isReady = self.session.isRunning
                }
            }
            return
        }
        setupSession(generation: generation)
    }

    private func setupSession(generation: Int) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard generation == self.sessionGeneration else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else {
                self.session.commitConfiguration()
                Task { @MainActor in
                    self.permissionDenied = true
                    self.isReady = false
                }
                return
            }

            self.session.addInput(input)
            if self.session.canAddOutput(self.photoOutput) { self.session.addOutput(self.photoOutput) }
            if self.session.canAddOutput(self.movieOutput) { self.session.addOutput(self.movieOutput) }
            self.session.commitConfiguration()

            guard generation == self.sessionGeneration else { return }
            self.session.startRunning()

            Task { @MainActor in
                guard generation == self.sessionGeneration else { return }
                self.isConfigured = true
                self.isReady = self.session.isRunning
            }
        }
    }

    func capturePhoto() {
        guard isReady, !isRecording else { return }
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func startRecording() {
        guard isReady, !movieOutput.isRecording else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("nocoos-\(UUID().uuidString).mov")
        movieOutput.startRecording(to: url, recordingDelegate: self)
        isRecording = true
        recordingDuration = 0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.recordingDuration += 0.1 }
        }
    }

    func stopRecording() {
        guard movieOutput.isRecording else {
            recordingTimer?.invalidate()
            recordingTimer = nil
            isRecording = false
            return
        }
        movieOutput.stopRecording()
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
    }

    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        Task { @MainActor in
            withAnimation(NOCOOSTheme.spring()) { lastCapture = image }
        }
    }

    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        Task { @MainActor in
            if error == nil {
                lastVideoURL = outputFileURL
            }
            isRecording = false
            recordingTimer?.invalidate()
            recordingTimer = nil
        }
    }

    func saveToPhotos(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
    }

    func stop() {
        sessionGeneration += 1
        let generation = sessionGeneration
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        }
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        isReady = false

        sessionQueue.async { [weak self] in
            guard let self else { return }
            // Only stop if this teardown still owns the generation.
            if generation == self.sessionGeneration, self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {}
}

final class CameraPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer {
        // Safe: layerClass forces AVCaptureVideoPreviewLayer.
        layer as! AVCaptureVideoPreviewLayer
    }
}

struct VideoPreviewView: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .onAppear { player = AVPlayer(url: url) }
            .onDisappear {
                player?.pause()
                player = nil
            }
    }
}
