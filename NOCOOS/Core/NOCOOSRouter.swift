import SwiftUI
import Combine

@MainActor
final class NOCOOSRouter: ObservableObject {
    @Published var activeApp: NOCOAppID?
    @Published var showSpotlight = false
    @Published var launchOrigin: CGRect = .zero
    @Published var isLaunchAnimating = false
    @Published var notesLaunchAction: NotesLaunchAction?

    enum NotesLaunchAction {
        case createNew
        case openNote(UUID)
        case search(String)
    }

    func open(_ app: NOCOAppID, from frame: CGRect = .zero) {
        guard activeApp != app else { return }
        NOCOOSTheme.mediumHaptic()
        launchOrigin = frame
        isLaunchAnimating = true
        withAnimation(NOCOOSTheme.spring(response: 0.48, damping: 0.86)) {
            activeApp = app
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            self.isLaunchAnimating = false
        }
    }

    func closeApp() {
        NOCOOSTheme.lightHaptic()
        withAnimation(NOCOOSTheme.spring(response: 0.44, damping: 0.88)) {
            activeApp = nil
            notesLaunchAction = nil
        }
    }

    func openSpotlight() {
        NOCOOSTheme.selectionHaptic()
        withAnimation(NOCOOSTheme.spring()) {
            showSpotlight = true
        }
    }

    func closeSpotlight() {
        withAnimation(NOCOOSTheme.spring()) {
            showSpotlight = false
        }
    }

    func openNotes(createNew: Bool = false, noteID: UUID? = nil, search: String? = nil) {
        if createNew {
            notesLaunchAction = .createNew
        } else if let noteID {
            notesLaunchAction = .openNote(noteID)
        } else if let search {
            notesLaunchAction = .search(search)
        }
        open(.notes)
    }
}
