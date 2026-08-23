import Foundation

@MainActor
final class AppLauncherService {
    private let router: NOCOOSRouter

    init(router: NOCOOSRouter) {
        self.router = router
    }

    func execute(_ intent: NOCOIntent) {
        switch intent {
        case .openApp(let app):
            router.open(app)
        case .createNote:
            router.openNotes(createNew: true)
        case .searchNotes(let query):
            router.openNotes(search: query)
        case .summarizeNotes, .summarizeText, .askAI, .unknown:
            router.open(.nocoAI)
        }
    }
}
