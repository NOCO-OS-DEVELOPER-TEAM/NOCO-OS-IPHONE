import SwiftUI
import Combine

@MainActor
final class NOCOOSRouter: ObservableObject {
    @Published var activeApp: NOCOAppID?
    @Published var showSpotlight = false
    @Published var notesLaunchAction: NotesLaunchAction?
    @Published var notesLaunchToken = UUID()
    @Published var cameraLaunchMode: CameraLaunchMode = .photo

    private var launchAnimationGeneration = 0

    enum NotesLaunchAction: Equatable {
        case createNew
        case createWithTitle(String)
        case openNote(UUID)
        case openLast
        case search(String)
    }

    enum CameraLaunchMode: Equatable {
        case photo
        case video
    }

    func open(_ app: NOCOAppID, from frame: CGRect = .zero) {
        _ = frame
        if activeApp == app { return }
        NOCOOSTheme.mediumHaptic()
        launchAnimationGeneration += 1
        let generation = launchAnimationGeneration
        withAnimation(NOCOOSTheme.spring(response: 0.48, dampingFraction: 0.86)) {
            activeApp = app
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self, generation == self.launchAnimationGeneration else { return }
        }
    }

    func closeApp() {
        NOCOOSTheme.lightHaptic()
        launchAnimationGeneration += 1
        withAnimation(NOCOOSTheme.spring(response: 0.44, dampingFraction: 0.88)) {
            activeApp = nil
            notesLaunchAction = nil
            cameraLaunchMode = .photo
        }
    }

    func openSpotlight() {
        guard !showSpotlight else { return }
        NOCOOSTheme.selectionHaptic()
        withAnimation(NOCOOSTheme.spring(response: 0.42, dampingFraction: 0.88)) {
            showSpotlight = true
        }
    }

    func closeSpotlight() {
        withAnimation(NOCOOSTheme.spring(response: 0.38, dampingFraction: 0.9)) {
            showSpotlight = false
        }
    }

    func openNotes(
        createNew: Bool = false,
        createWithTitle: String? = nil,
        noteID: UUID? = nil,
        openLast: Bool = false,
        search: String? = nil
    ) {
        if createNew {
            notesLaunchAction = .createNew
        } else if let createWithTitle {
            notesLaunchAction = .createWithTitle(createWithTitle)
        } else if openLast {
            notesLaunchAction = .openLast
        } else if let noteID {
            notesLaunchAction = .openNote(noteID)
        } else if let search {
            notesLaunchAction = .search(search)
        }
        notesLaunchToken = UUID()
        if activeApp != .notes {
            open(.notes)
        }
    }

    func openCamera(mode: CameraLaunchMode = .photo) {
        cameraLaunchMode = mode
        open(.camera)
    }
}
