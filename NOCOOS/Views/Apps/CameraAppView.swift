import SwiftUI
import AVFoundation
import Photos

struct CameraAppView: View {
    @EnvironmentObject private var connection: ConnectionStore
    @EnvironmentObject private var settings: SettingsStore

    @StateObject private var model = CameraModel()
    @State private var analysisResult = ""
    @State private var showAnalysis = false
    @State private var isAnalyzing = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                CameraPreview(session: model.session)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay {
                        if model.permissionDenied {
                            ContentUnavailableView(
                                "Kamera nicht erlaubt",
                                systemImage: "camera.fill",
                                description: Text("Bitte Kamera-Zugriff in den iOS-Einstellungen erlauben.")
                            )
                        }
                    }

                if let image = model.lastCapture {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .frame(maxHeight: .infinity)
            .padding(12)

            controls
        }
        .onAppear { model.configure() }
        .onDisappear { model.stop() }
        .alert("NOCO AI Analyse", isPresented: $showAnalysis) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(analysisResult)
        }
    }

    private var controls: some View {
        HStack(spacing: 28) {
            Button {
                model.lastCapture = nil
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
            }
            .foregroundStyle(.white)
            .disabled(model.lastCapture == nil)

            Button {
                model.capturePhoto()
                NOCOOSTheme.mediumHaptic()
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 4)
                        .frame(width: 72, height: 72)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 58, height: 58)
                }
            }
            .buttonStyle(.plain)

            Button {
                Task { await analyzePhoto() }
            } label: {
                if isAnalyzing {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "sparkles")
                        .font(.title2)
                }
            }
            .foregroundStyle(NOCOOSTheme.accentGlow)
            .disabled(model.lastCapture == nil || isAnalyzing)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.35))
    }

    private func analyzePhoto() async {
        guard let image = model.lastCapture else { return }
        isAnalyzing = true
        defer { isAnalyzing = false }

        model.saveToPhotos(image)

        guard connection.isPaired, let api = connection.api else {
            analysisResult = "Foto gespeichert. Für Bildanalyse NOCO AI Server verbinden."
            showAnalysis = true
            return
        }

        do {
            let reply = try await api.chat(
                prompt: "Der Nutzer hat ein Foto in NOCO OS aufgenommen. Beschreibe kurz, was typischerweise auf einem Alltagsfoto zu sehen sein könnte, und gib Tipps zur Textanalyse per OCR, sobald Bild-Upload unterstützt wird.",
                model: nil,
                notesContext: "Foto aufgenommen in NOCO OS Kamera."
            )
            analysisResult = reply
            showAnalysis = true
            settings.log("Camera AI analysis requested")
        } catch {
            analysisResult = "Foto gespeichert. Analyse fehlgeschlagen: \(error.localizedDescription)"
            showAnalysis = true
        }
    }
}

@MainActor
final class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var lastCapture: UIImage?
    @Published var permissionDenied = false

    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var isConfigured = false

    func configure() {
        guard !isConfigured else {
            if !session.isRunning { session.startRunning() }
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted {
                        self.setupSession()
                    } else {
                        self.permissionDenied = true
                    }
                }
            }
        default:
            permissionDenied = true
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input),
            session.canAddOutput(output)
        else {
            permissionDenied = true
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        session.addOutput(output)
        session.commitConfiguration()
        session.startRunning()
        isConfigured = true
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        Task { @MainActor in
            withAnimation(NOCOOSTheme.spring()) {
                lastCapture = image
            }
        }
    }

    func saveToPhotos(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
    }

    func stop() {
        if session.isRunning { session.stopRunning() }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        context.coordinator.preview = preview
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.preview?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var preview: AVCaptureVideoPreviewLayer?
    }
}
