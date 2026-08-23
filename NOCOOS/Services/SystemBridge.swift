import Foundation
import UIKit

@MainActor
final class SystemBridge: ObservableObject {
    @Published var lastCapturedImage: UIImage?
    @Published var pendingCameraAnalysis = false
    @Published var pendingNoteFromText: String?

    func registerCapture(_ image: UIImage) {
        lastCapturedImage = image
    }

    func requestCameraAnalysis() {
        pendingCameraAnalysis = true
    }

    func consumeCameraAnalysisRequest() -> Bool {
        guard pendingCameraAnalysis else { return false }
        pendingCameraAnalysis = false
        return true
    }

    func createNoteFromText(_ text: String) {
        pendingNoteFromText = text
    }

    func consumeNoteFromText() -> String? {
        defer { pendingNoteFromText = nil }
        return pendingNoteFromText
    }
}
